const {ethers}=require("hardhat");

const networkConfig={
    default:{
        name:"hardhat",
        keepersUpdateInterval:"30"
    },
    31337:{
        name:"localhost",
        subscriptionId:"588",
        keyHash: "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c", // 30 gwei
        keepersUpdateInterval: "30",
        raffleEntranceFee: ethers.parseEther("0.01"), // 0.01 ETH
        callbackGasLimit: "500000", // 500,000 gas
    },
    11155111: {
        name: "sepolia",
        subscriptionId: "PEnding",
        keyHash: "0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae", // 30 gwei
        keepersUpdateInterval: "30",
        raffleEntranceFee: ethers.parseEther("0.01"), // 0.01 ETH
        callbackGasLimit: "500000", // 500,000 gas
        vrfCoordinatorV2: "0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B",
    },
    1: {
        name: "mainnet",
        keepersUpdateInterval: "30",
    },
}

const developmentChains = ["hardhat", "localhost"]
const VERIFICATION_BLOCK_CONFIRMATIONS = 6;

module.exports={
    networkConfig,
    developmentChains,
    VERIFICATION_BLOCK_CONFIRMATIONS
}