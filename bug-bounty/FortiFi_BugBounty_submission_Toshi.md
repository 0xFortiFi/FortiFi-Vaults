# Critical Findings

1. [C] Improper implementation of `Bricking` feature. No safety check to ensure FortiFiStrategies are not set as bricked in the Vault contracts, which would lead to loss of user funds if improperly set. When FortiFiStrategies are set as bricked, depending on their place in the array of strategies they may fail without manual intervention (sending deposit tokens to the contract before withdrawal).

2. [C] Slippage calculation in `FortiFiMASSVault:_swapToDepositTokenDirect` will round to 0 if `strat.decimals` is more than 8.

3. [C] Slippage in FortiFiGLPFortress and FortiFiGLPFortressArb for deposits rounds to 0 due to improper division before multiplication.

# Low-High Findings

0. [L-H] Generally across the entire codebase there are many occurances of divison before multiplication. This truncates intermediate calculations since there's no floats in EVM. I've called out multiple occurances where this results in a critical vuln, but there are many other occurances which range from Low-High severity. Rather than calling them all out as separate issues, the codebase should be refactored to always multiply prior to dividing.

1. [H] Slippage calculation in `FortiFiWNativeMASSVault:_swapToDepositTokenDirect[line 384]` can round to 0 when `_amount` is sufficiently small (~1 AVAX) & there is a depeg of the (in this case liquid staking token (sAVAX)). This is due to doing division prior to multiplication. This is likely the last explicit bug I'll call out for math reasons specifically.

2. [H] Slippage calculation on Wombat withdrawals (and deposits) in `FortiFiWombatFortress:withdrawWombat[line 113]` of `(_lpReceived * (BPS - _slippage) / BPS)` is not correct. This does not correspond to the actual value you are expected to receive when withdrawing. The slippage should likely be based on the `quotePotentialWithdraw` and `quotePotentialDeposit` functions on the pool. 

3. [H] If a strategy gets bricked and the user calls `FortiFiMASSVaultV2:rebalance` (rather than `withdraw` and `deposit` individually) then `tokenInfo[_tokenId].deposit` will be too high, which will result in the user paying less or no protocol fees in the future. This is because the `tokenInfo[_tokenId].deposit` value includes the original deposit into the now-bricked strategy, even though that amount is not deposited in the `_deposit` call.

4. [H] Across the entire protocol the use of `block.timestamp` in the swap slippage calculation is invalid (e.g. `FortiFiMASSVaultV2[line 359]` and `FortiFiWombatFortress[line 73]`). This will pass at all times because block.timestamp is calculation when the tx is included in a block rather than when it is created. This parameter needs to be a parameter in the function call.

5. [H] In multiple places in `FortiFiMASSVaultV2`, the slippage calculated for USDC assumes that USDC is equivalent to 1 USD which isn't valid (recall the USDC depeg). A practical implication of this is in `FortiFiMASSVaultV2[line 380]` where a USDC depeg will result in the swap potentially failing due to overpricing the value of USDC (when calculating the acceptable slippage amount). Suggest also referencing the USDC/USD price feed to get the USDC-USD conversion.

6. [H] Assuming in `FortiFiMASSVaultV2:_refund[line 556]` that the depositor gets some `depositToken` back, the `_info.deposit` amount is not correctly decremented since `_info` is passed in `memory`. There's another implication of this where you can DOS `_deposit` calls by transferring in `depositToken` amount > `_info.deposit`, which will make the subtraction revert.

7. [M] The current logic across the entire protocol will not support fee-on-transfer tokens (e.g. USDT on Ethereum). Suggest future-proofing this codebase by making changes to support these tokens (e.g. checking the balance change from transferring to determine the actual deposited amount).

8. [M] Some tokens require that their approval amount is 0 prior to approving a non-zero amount (e.g. USDT on Ethereum). This can be an issue in `FortiFiMASSVaultV2:setStrategies[line 289]`, where if the approval amount for a token is > 0 then this will revert. Suggest doing approve(0) prior to approving the max amount again.

9. [M] There is an invalid assumption that all chainlink USD feeds use 8 decimals of precision (e.g. `fortiFiMAssVaultV2[line 280]`). Be aware of this. For example: https://data.chain.link/feeds/ethereum/mainnet/ampl-usd.

10. [M] Hardcoded staleness check of 75 min in chainlink oracle integration `FortiFiPriceOracle[line 40]` does not work for all datafeeds. Check out https://data.chain.link/feeds/ethereum/mainnet/1inch-eth as an example, where unless the price deviation hits 2%, there will not be an update to the price feed until 24 hours have passed since the last one.

11. [M] Chainlink oracle integration does not have logic to handle the case when minAnswer and maxAnswer are hit. Check out: https://github.com/sherlock-audit/2023-02-blueberry-judging/issues/18.


12. [L] Unnecessary logic across the protocol such as `FortiFiFeeManager:_validateBps` (where it will revert if fails, but there is an unecessary check on `FortiFiFeeManager[line 72]` which effectively just checks this again).

13. [L] Based on GMX documentation for selling you should be using `glpManager.getPrice(false)` for selling. Referencing `FortiFiGLPFortress[line 90]`, https://gmx-docs.io/docs/api/contracts-v1/.

14. [L] Flash-borrowed NFTs can be used to get lower fees in `FortiFiFeeCalculator:_getFees`.

15. [L] There's unnecessary `receive` functions in multiple contracts which should not be receiveing AVAX, which can be used to trigger arbitrary callbacks.



# Informational Findings

1. `FortiFiFortress:withdrawBricked[line 112]`: `_balance = _strat.balanceOf(address(this));` is repeated

2. Generally good to not have hardcoded addresses for contracts intended to be used on multiple chains as it can lead to unintentional errors (such as setting the GMX addresses in the contract).

3. There is unnecessary code such as `FortiFiMASSVaultV2:_withdraw[line 515]` - what is the purpose of initializing `_proceeds`?

4. Unused contracts should be removed from the codebase (such as the MASSVault V1).

5. Remove functions which are not being used: such as `FortiFiWombatFortress:withdraw` and `deposit` (this is also there in the Vector Finance integration).

6. Consider refactoring `FortiFiMASSVaultV2` and the Native version to use the same base contract with shared functionality. Having multiple copies of the same code can lead to errors.

7. There's a lot of code which will likely not be used which leads to wasted gas (most of the refunding logic).













