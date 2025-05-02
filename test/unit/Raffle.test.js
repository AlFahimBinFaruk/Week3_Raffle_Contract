const {assert, expect} = require('chai');
const {ethers,network,deployments, getNamedAccounts} = require('hardhat');
const {developmentChains,networkConfig} = require('../../helper-hardhat-config');


!developmentChains.includes(network.name)
? describe.skip
: describe("Raffle Unit Tests",function(){
    let raffle,raffleContract,vrfCoordinatorV2Mock, raffleEntranceFee, interval, player,deployer;

    beforeEach(async()=>{

        // deploy all contracts;
        await deployments.fixture(["all"]);

        deployer=(await getNamedAccounts()).deployer;

        // get the contracts to interact with them.
        const raffleDeployment=await deployments.get("Raffle");
        raffle=await ethers.getContractAt("Raffle",raffleDeployment.address);

        const mockDeployment=await deployments.get("Raffle");
        vrfCoordinatorV2Mock=await ethers.getContractAt("VRFCoordinatorV2Mock",mockDeployment.address);

        interval=await raffle.getInterval();
    });




    describe("Constructor",function(){
        it("initializes the raffle correctly",async()=>{
            const raffleState=(await raffle.getRaffleState()).toString();
            assert.equal(raffleState,"0");
            assert.equal(interval.toString(),networkConfig[network.config.chainId]["keepersUpdateInterval"]);
        });
    })


})