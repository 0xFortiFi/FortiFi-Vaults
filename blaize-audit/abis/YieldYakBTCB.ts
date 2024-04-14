export const yieldYakBTCB_ABI = [
    {
        inputs: [
            { internalType: "string", name: "_name", type: "string" },
            { internalType: "address", name: "_depositToken", type: "address" },
            { internalType: "address", name: "_poolRewardToken", type: "address" },
            {
                components: [
                    { internalType: "address", name: "swapPairToken", type: "address" },
                    { internalType: "address", name: "swapPairPoolReward", type: "address" },
                    { internalType: "address", name: "swapPairExtraReward", type: "address" }
                ],
                internalType: "struct PlatypusStrategy.SwapPairs",
                name: "swapPairs",
                type: "tuple"
            },
            { internalType: "uint256", name: "_maxSlippage", type: "uint256" },
            { internalType: "address", name: "_pool", type: "address" },
            { internalType: "address", name: "_stakingContract", type: "address" },
            { internalType: "address", name: "_voterProxy", type: "address" },
            { internalType: "uint256", name: "_pid", type: "uint256" },
            { internalType: "address", name: "_timelock", type: "address" },
            {
                components: [
                    { internalType: "uint256", name: "minTokensToReinvest", type: "uint256" },
                    { internalType: "uint256", name: "devFeeBips", type: "uint256" },
                    { internalType: "uint256", name: "reinvestRewardBips", type: "uint256" }
                ],
                internalType: "struct YakStrategyV2.StrategySettings",
                name: "_strategySettings",
                type: "tuple"
            }
        ],
        stateMutability: "nonpayable",
        type: "constructor"
    },
    {
        anonymous: false,
        inputs: [{ indexed: true, internalType: "address", name: "account", type: "address" }],
        name: "AllowDepositor",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: true, internalType: "address", name: "owner", type: "address" },
            { indexed: true, internalType: "address", name: "spender", type: "address" },
            { indexed: false, internalType: "uint256", name: "value", type: "uint256" }
        ],
        name: "Approval",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: true, internalType: "address", name: "account", type: "address" },
            { indexed: false, internalType: "uint256", name: "amount", type: "uint256" }
        ],
        name: "Deposit",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [{ indexed: false, internalType: "bool", name: "newValue", type: "bool" }],
        name: "DepositsEnabled",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: true, internalType: "address", name: "previousOwner", type: "address" },
            { indexed: true, internalType: "address", name: "newOwner", type: "address" }
        ],
        name: "OwnershipTransferred",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: false, internalType: "address", name: "token", type: "address" },
            { indexed: false, internalType: "uint256", name: "amount", type: "uint256" }
        ],
        name: "Recovered",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: false, internalType: "uint256", name: "newTotalDeposits", type: "uint256" },
            { indexed: false, internalType: "uint256", name: "newTotalSupply", type: "uint256" }
        ],
        name: "Reinvest",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [{ indexed: true, internalType: "address", name: "account", type: "address" }],
        name: "RemoveDepositor",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: true, internalType: "address", name: "from", type: "address" },
            { indexed: true, internalType: "address", name: "to", type: "address" },
            { indexed: false, internalType: "uint256", name: "value", type: "uint256" }
        ],
        name: "Transfer",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: false, internalType: "uint256", name: "oldValue", type: "uint256" },
            { indexed: false, internalType: "uint256", name: "newValue", type: "uint256" }
        ],
        name: "UpdateAdminFee",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: false, internalType: "address", name: "oldValue", type: "address" },
            { indexed: false, internalType: "address", name: "newValue", type: "address" }
        ],
        name: "UpdateDevAddr",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: false, internalType: "uint256", name: "oldValue", type: "uint256" },
            { indexed: false, internalType: "uint256", name: "newValue", type: "uint256" }
        ],
        name: "UpdateDevFee",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: false, internalType: "uint256", name: "oldValue", type: "uint256" },
            { indexed: false, internalType: "uint256", name: "newValue", type: "uint256" }
        ],
        name: "UpdateMaxTokensToDepositWithoutReinvest",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: false, internalType: "uint256", name: "oldValue", type: "uint256" },
            { indexed: false, internalType: "uint256", name: "newValue", type: "uint256" }
        ],
        name: "UpdateMinTokensToReinvest",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: false, internalType: "uint256", name: "oldValue", type: "uint256" },
            { indexed: false, internalType: "uint256", name: "newValue", type: "uint256" }
        ],
        name: "UpdateReinvestReward",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: true, internalType: "address", name: "account", type: "address" },
            { indexed: false, internalType: "uint256", name: "amount", type: "uint256" }
        ],
        name: "Withdraw",
        type: "event"
    },
    {
        inputs: [],
        name: "ADMIN_FEE_BIPS",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "DEPOSITS_ENABLED",
        outputs: [{ internalType: "bool", name: "", type: "bool" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "DEV_FEE_BIPS",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "DOMAIN_TYPEHASH",
        outputs: [{ internalType: "bytes32", name: "", type: "bytes32" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "MIN_TOKENS_TO_REINVEST",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "PERMIT_TYPEHASH",
        outputs: [{ internalType: "bytes32", name: "", type: "bytes32" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "PID",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "REINVEST_REWARD_BIPS",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "VERSION_HASH",
        outputs: [{ internalType: "bytes32", name: "", type: "bytes32" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [{ internalType: "address", name: "depositor", type: "address" }],
        name: "allowDepositor",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [
            { internalType: "address", name: "account", type: "address" },
            { internalType: "address", name: "spender", type: "address" }
        ],
        name: "allowance",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [{ internalType: "address", name: "", type: "address" }],
        name: "allowedDepositors",
        outputs: [{ internalType: "bool", name: "", type: "bool" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [
            { internalType: "address", name: "spender", type: "address" },
            { internalType: "uint256", name: "amount", type: "uint256" }
        ],
        name: "approve",
        outputs: [{ internalType: "bool", name: "", type: "bool" }],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [],
        name: "asset",
        outputs: [{ internalType: "contract IPlatypusAsset", name: "", type: "address" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [{ internalType: "address", name: "account", type: "address" }],
        name: "balanceOf",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "checkReward",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "decimals",
        outputs: [{ internalType: "uint8", name: "", type: "uint8" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [{ internalType: "uint256", name: "amount", type: "uint256" }],
        name: "deposit",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [
            { internalType: "address", name: "account", type: "address" },
            { internalType: "uint256", name: "amount", type: "uint256" }
        ],
        name: "depositFor",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [],
        name: "depositToken",
        outputs: [{ internalType: "contract IERC20", name: "", type: "address" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [
            { internalType: "uint256", name: "amount", type: "uint256" },
            { internalType: "uint256", name: "deadline", type: "uint256" },
            { internalType: "uint8", name: "v", type: "uint8" },
            { internalType: "bytes32", name: "r", type: "bytes32" },
            { internalType: "bytes32", name: "s", type: "bytes32" }
        ],
        name: "depositWithPermit",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [],
        name: "devAddr",
        outputs: [{ internalType: "address", name: "", type: "address" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "estimateDeployedBalance",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "estimateReinvestReward",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "extraToken",
        outputs: [{ internalType: "address", name: "", type: "address" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [{ internalType: "uint256", name: "amount", type: "uint256" }],
        name: "getDepositTokensForShares",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "getDomainSeparator",
        outputs: [{ internalType: "bytes32", name: "", type: "bytes32" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [{ internalType: "uint256", name: "amount", type: "uint256" }],
        name: "getSharesForDepositTokens",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "masterchef",
        outputs: [{ internalType: "contract IMasterPlatypus", name: "", type: "address" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "maxSlippage",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "name",
        outputs: [{ internalType: "string", name: "", type: "string" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [{ internalType: "address", name: "", type: "address" }],
        name: "nonces",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "numberOfAllowedDepositors",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "owner",
        outputs: [{ internalType: "address", name: "", type: "address" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [
            { internalType: "address", name: "owner", type: "address" },
            { internalType: "address", name: "spender", type: "address" },
            { internalType: "uint256", name: "value", type: "uint256" },
            { internalType: "uint256", name: "deadline", type: "uint256" },
            { internalType: "uint8", name: "v", type: "uint8" },
            { internalType: "bytes32", name: "r", type: "bytes32" },
            { internalType: "bytes32", name: "s", type: "bytes32" }
        ],
        name: "permit",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [],
        name: "pool",
        outputs: [{ internalType: "contract IPlatypusPool", name: "", type: "address" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "proxy",
        outputs: [{ internalType: "contract IPlatypusVoterProxy", name: "", type: "address" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [{ internalType: "uint256", name: "amount", type: "uint256" }],
        name: "recoverAVAX",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [
            { internalType: "address", name: "tokenAddress", type: "address" },
            { internalType: "uint256", name: "tokenAmount", type: "uint256" }
        ],
        name: "recoverERC20",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    { inputs: [], name: "reinvest", outputs: [], stateMutability: "nonpayable", type: "function" },
    {
        inputs: [{ internalType: "address", name: "depositor", type: "address" }],
        name: "removeDepositor",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    { inputs: [], name: "renounceOwnership", outputs: [], stateMutability: "nonpayable", type: "function" },
    {
        inputs: [
            { internalType: "uint256", name: "minReturnAmountAccepted", type: "uint256" },
            { internalType: "bool", name: "disableDeposits", type: "bool" }
        ],
        name: "rescueDeployedFunds",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [
            { internalType: "address", name: "token", type: "address" },
            { internalType: "address", name: "spender", type: "address" }
        ],
        name: "revokeAllowance",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [],
        name: "rewardToken",
        outputs: [{ internalType: "contract IERC20", name: "", type: "address" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [{ internalType: "address", name: "_extraTokenSwapPair", type: "address" }],
        name: "setExtraRewardSwapPair",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [{ internalType: "address", name: "_voterProxy", type: "address" }],
        name: "setPlatypusVoterProxy",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [],
        name: "swapPairExtraReward",
        outputs: [{ internalType: "address", name: "", type: "address" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "symbol",
        outputs: [{ internalType: "string", name: "", type: "string" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "totalDeposits",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "totalSupply",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [
            { internalType: "address", name: "dst", type: "address" },
            { internalType: "uint256", name: "amount", type: "uint256" }
        ],
        name: "transfer",
        outputs: [{ internalType: "bool", name: "", type: "bool" }],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [
            { internalType: "address", name: "src", type: "address" },
            { internalType: "address", name: "dst", type: "address" },
            { internalType: "uint256", name: "amount", type: "uint256" }
        ],
        name: "transferFrom",
        outputs: [{ internalType: "bool", name: "", type: "bool" }],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [{ internalType: "address", name: "newOwner", type: "address" }],
        name: "transferOwnership",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [{ internalType: "uint256", name: "newValue", type: "uint256" }],
        name: "updateAdminFee",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [{ internalType: "bool", name: "newValue", type: "bool" }],
        name: "updateDepositsEnabled",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [{ internalType: "address", name: "newValue", type: "address" }],
        name: "updateDevAddr",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [{ internalType: "uint256", name: "newValue", type: "uint256" }],
        name: "updateDevFee",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [{ internalType: "uint256", name: "slippageBips", type: "uint256" }],
        name: "updateMaxSwapSlippage",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [{ internalType: "uint256", name: "newValue", type: "uint256" }],
        name: "updateMaxTokensToDepositWithoutReinvest",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [{ internalType: "uint256", name: "newValue", type: "uint256" }],
        name: "updateMinTokensToReinvest",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [{ internalType: "uint256", name: "newValue", type: "uint256" }],
        name: "updateReinvestReward",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [{ internalType: "uint256", name: "amount", type: "uint256" }],
        name: "withdraw",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    }
];
