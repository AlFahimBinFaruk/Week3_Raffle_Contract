const {network,ethers}=require("hardhat");

const {
    networkConfig,
    developmentChains,
    VERIFICATION_BLOCK_CONFIRMATIONS
}=require("../helper-hardhat-config");


const { verify } = require("../utils/verify");


module.exports=async({getNamedAccounts,deployments})=>{
    const {deploy,log}=deployments;
    const {deployer}=await getNamedAccounts();
    const chainId=network.config.chainId;

    let vrfCoordinatorV2Address;

    if(chainId==31337){
        let vrfCoordinatorV2Mock=await deployments.get("VRFCoordinatorV2Mock");
        vrfCoordinatorV2Address=vrfCoordinatorV2Mock.address;
        // subscriptionId = networkConfig[chainId]["subscriptionId"];
    }else{
        vrfCoordinatorV2Address=networkConfig[chainId]["vrfCoordinatorV2"];
        // subscriptionId = networkConfig[chainId]["subscriptionId"];
    }

    // console.log("addess is => ",vrfCoordinatorV2Address);

    const waitBlockConfirmations = developmentChains.includes(network.name) ? 1 : VERIFICATION_BLOCK_CONFIRMATIONS;

    log("----------------------------------------------------");
    

    const arguments=[
        vrfCoordinatorV2Address,
        networkConfig[chainId]["raffleEntranceFee"],
        networkConfig[chainId]["keyHash"],
        networkConfig[chainId]["subscriptionId"],
        networkConfig[chainId]["callbackGasLimit"],
        networkConfig[chainId]["keepersUpdateInterval"]
    ];

    const raffle=await deploy("Raffle",{
        from:deployer,
        args:arguments,
        log:true,
        waitBlockConfirmations:waitBlockConfirmations
    });

    if(!developmentChains.includes(network.name)){
        log("Verifying....");
        verify(raffle.address,arguments);
    }

    log("Enter lottery with command:");
    const networkName = network.name == "hardhat" ? "localhost" : network.name;
    log(`yarn hardhat run scripts/enterRaffle.js --network ${networkName}`);
    log("----------------------------------------------------");

}

module.exports.tags=["all","raffle"];