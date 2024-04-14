export const deltaPrimeUSDC_ABI = [
    { inputs: [], name: "BorrowersRegistryNotConfigured", type: "error" },
    { inputs: [], name: "BurnAmountExceedsAvailableForUser", type: "error" },
    { inputs: [], name: "BurnAmountExceedsBalance", type: "error" },
    {
        inputs: [
            { internalType: "uint256", name: "requested", type: "uint256" },
            { internalType: "uint256", name: "allowance", type: "uint256" }
        ],
        name: "InsufficientAllowance",
        type: "error"
    },
    { inputs: [], name: "InsufficientPoolFunds", type: "error" },
    { inputs: [], name: "InsufficientSurplus", type: "error" },
    { inputs: [], name: "MaxPoolUtilisationBreached", type: "error" },
    { inputs: [], name: "MintToAddressZero", type: "error" },
    { inputs: [{ internalType: "address", name: "target", type: "address" }], name: "NotAContract", type: "error" },
    { inputs: [], name: "NotAuthorizedToBorrow", type: "error" },
    { inputs: [], name: "PoolFrozen", type: "error" },
    { inputs: [], name: "RepayingMoreThanWasBorrowed", type: "error" },
    { inputs: [], name: "SpenderZeroAddress", type: "error" },
    { inputs: [], name: "TotalSupplyCapBreached", type: "error" },
    {
        inputs: [
            { internalType: "uint256", name: "amount", type: "uint256" },
            { internalType: "uint256", name: "balance", type: "uint256" }
        ],
        name: "TransferAmountExceedsBalance",
        type: "error"
    },
    { inputs: [], name: "TransferToPoolAddress", type: "error" },
    { inputs: [], name: "TransferToZeroAddress", type: "error" },
    { inputs: [], name: "ZeroDepositAmount", type: "error" },
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
            { indexed: true, internalType: "address", name: "registry", type: "address" },
            { indexed: false, internalType: "uint256", name: "timestamp", type: "uint256" }
        ],
        name: "BorrowersRegistryChanged",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: true, internalType: "address", name: "user", type: "address" },
            { indexed: false, internalType: "uint256", name: "value", type: "uint256" },
            { indexed: false, internalType: "uint256", name: "timestamp", type: "uint256" }
        ],
        name: "Borrowing",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: true, internalType: "address", name: "user", type: "address" },
            { indexed: false, internalType: "uint256", name: "value", type: "uint256" },
            { indexed: false, internalType: "uint256", name: "timestamp", type: "uint256" }
        ],
        name: "Deposit",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: true, internalType: "address", name: "user", type: "address" },
            { indexed: true, internalType: "address", name: "_of", type: "address" },
            { indexed: false, internalType: "uint256", name: "value", type: "uint256" },
            { indexed: false, internalType: "uint256", name: "timestamp", type: "uint256" }
        ],
        name: "DepositOnBehalfOf",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: true, internalType: "address", name: "user", type: "address" },
            { indexed: false, internalType: "uint256", name: "value", type: "uint256" },
            { indexed: false, internalType: "uint256", name: "timestamp", type: "uint256" }
        ],
        name: "InterestCollected",
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
            { indexed: true, internalType: "address", name: "poolRewarder", type: "address" },
            { indexed: false, internalType: "uint256", name: "timestamp", type: "uint256" }
        ],
        name: "PoolRewarderChanged",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: true, internalType: "address", name: "calculator", type: "address" },
            { indexed: false, internalType: "uint256", name: "timestamp", type: "uint256" }
        ],
        name: "RatesCalculatorChanged",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: true, internalType: "address", name: "user", type: "address" },
            { indexed: false, internalType: "uint256", name: "value", type: "uint256" },
            { indexed: false, internalType: "uint256", name: "timestamp", type: "uint256" }
        ],
        name: "Repayment",
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
            { indexed: true, internalType: "address", name: "distributor", type: "address" },
            { indexed: false, internalType: "uint256", name: "timestamp", type: "uint256" }
        ],
        name: "VestingDistributorChanged",
        type: "event"
    },
    {
        anonymous: false,
        inputs: [
            { indexed: true, internalType: "address", name: "user", type: "address" },
            { indexed: false, internalType: "uint256", name: "value", type: "uint256" },
            { indexed: false, internalType: "uint256", name: "timestamp", type: "uint256" }
        ],
        name: "Withdrawal",
        type: "event"
    },
    {
        inputs: [
            { internalType: "address", name: "owner", type: "address" },
            { internalType: "address", name: "spender", type: "address" }
        ],
        name: "allowance",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
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
        inputs: [{ internalType: "address", name: "user", type: "address" }],
        name: "balanceOf",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [{ internalType: "uint256", name: "_amount", type: "uint256" }],
        name: "borrow",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [],
        name: "borrowIndex",
        outputs: [{ internalType: "contract IIndex", name: "", type: "address" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [{ internalType: "address", name: "", type: "address" }],
        name: "borrowed",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "borrowersRegistry",
        outputs: [{ internalType: "contract IBorrowersRegistry", name: "", type: "address" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "checkRewards",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "decimals",
        outputs: [{ internalType: "uint8", name: "decimals", type: "uint8" }],
        stateMutability: "pure",
        type: "function"
    },
    {
        inputs: [
            { internalType: "address", name: "spender", type: "address" },
            { internalType: "uint256", name: "subtractedValue", type: "uint256" }
        ],
        name: "decreaseAllowance",
        outputs: [{ internalType: "bool", name: "", type: "bool" }],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [{ internalType: "uint256", name: "_amount", type: "uint256" }],
        name: "deposit",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [],
        name: "depositIndex",
        outputs: [{ internalType: "contract IIndex", name: "", type: "address" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [
            { internalType: "uint256", name: "_amount", type: "uint256" },
            { internalType: "address", name: "_of", type: "address" }
        ],
        name: "depositOnBehalf",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [{ internalType: "address", name: "_user", type: "address" }],
        name: "getBorrowed",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "getBorrowingRate",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "getDepositRate",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "getFullPoolStatus",
        outputs: [{ internalType: "uint256[5]", name: "", type: "uint256[5]" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "getMaxPoolUtilisationForBorrowing",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    { inputs: [], name: "getRewards", outputs: [], stateMutability: "nonpayable", type: "function" },
    {
        inputs: [
            { internalType: "address", name: "spender", type: "address" },
            { internalType: "uint256", name: "addedValue", type: "uint256" }
        ],
        name: "increaseAllowance",
        outputs: [{ internalType: "bool", name: "", type: "bool" }],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [
            { internalType: "contract IRatesCalculator", name: "ratesCalculator_", type: "address" },
            { internalType: "contract IBorrowersRegistry", name: "borrowersRegistry_", type: "address" },
            { internalType: "contract IIndex", name: "depositIndex_", type: "address" },
            { internalType: "contract IIndex", name: "borrowIndex_", type: "address" },
            { internalType: "address payable", name: "tokenAddress_", type: "address" },
            { internalType: "contract IPoolRewarder", name: "poolRewarder_", type: "address" },
            { internalType: "uint256", name: "_totalSupplyCap", type: "uint256" }
        ],
        name: "initialize",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [],
        name: "name",
        outputs: [{ internalType: "string", name: "_name", type: "string" }],
        stateMutability: "pure",
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
        inputs: [],
        name: "poolRewarder",
        outputs: [{ internalType: "contract IPoolRewarder", name: "", type: "address" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "ratesCalculator",
        outputs: [{ internalType: "contract IRatesCalculator", name: "", type: "address" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [
            { internalType: "uint256", name: "amount", type: "uint256" },
            { internalType: "address", name: "account", type: "address" }
        ],
        name: "recoverSurplus",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    { inputs: [], name: "renounceOwnership", outputs: [], stateMutability: "nonpayable", type: "function" },
    {
        inputs: [{ internalType: "uint256", name: "amount", type: "uint256" }],
        name: "repay",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [{ internalType: "contract IBorrowersRegistry", name: "borrowersRegistry_", type: "address" }],
        name: "setBorrowersRegistry",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [{ internalType: "contract IPoolRewarder", name: "_poolRewarder", type: "address" }],
        name: "setPoolRewarder",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [{ internalType: "contract IRatesCalculator", name: "ratesCalculator_", type: "address" }],
        name: "setRatesCalculator",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [{ internalType: "uint256", name: "_newTotalSupplyCap", type: "uint256" }],
        name: "setTotalSupplyCap",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [{ internalType: "address", name: "_distributor", type: "address" }],
        name: "setVestingDistributor",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [],
        name: "symbol",
        outputs: [{ internalType: "string", name: "_symbol", type: "string" }],
        stateMutability: "pure",
        type: "function"
    },
    {
        inputs: [],
        name: "tokenAddress",
        outputs: [{ internalType: "address payable", name: "", type: "address" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [],
        name: "totalBorrowed",
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
        inputs: [],
        name: "totalSupplyCap",
        outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [
            { internalType: "address", name: "recipient", type: "address" },
            { internalType: "uint256", name: "amount", type: "uint256" }
        ],
        name: "transfer",
        outputs: [{ internalType: "bool", name: "", type: "bool" }],
        stateMutability: "nonpayable",
        type: "function"
    },
    {
        inputs: [
            { internalType: "address", name: "sender", type: "address" },
            { internalType: "address", name: "recipient", type: "address" },
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
        inputs: [],
        name: "vestingDistributor",
        outputs: [{ internalType: "contract VestingDistributor", name: "", type: "address" }],
        stateMutability: "view",
        type: "function"
    },
    {
        inputs: [{ internalType: "uint256", name: "_amount", type: "uint256" }],
        name: "withdraw",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function"
    }
];
