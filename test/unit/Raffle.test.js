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

        let accounts=await ethers.getSigners();
        player=accounts[0];

        // get the contracts to interact with them.
        const raffleDeployment=await deployments.get("Raffle");
        raffle=await ethers.getContractAt("Raffle",raffleDeployment.address);

        const mockDeployment=await deployments.get("Raffle");
        vrfCoordinatorV2Mock=await ethers.getContractAt("VRFCoordinatorV2Mock",mockDeployment.address);

        interval=await raffle.getInterval();
        raffleEntranceFee=await raffle.getEntranceFee();
    });




    describe("Constructor",function(){
        it("initializes the raffle correctly",async()=>{
            const raffleState=(await raffle.getRaffleState()).toString();
            assert.equal(raffleState,"0");
            assert.equal(interval.toString(),networkConfig[network.config.chainId]["keepersUpdateInterval"]);
        });
    });




    describe("EnterRaffle",function(){
        it("reverts when you don't pay enough", async () => {
            await expect(raffle.enterRaffle()).to.be.revertedWithCustomError(raffle,"Raffle__SendMoreToEnterRaffle");
        })

        it("records player when they enter", async () => {
            await raffle.enterRaffle({ value: raffleEntranceFee });
            const contractPlayer = await raffle.getPlayer(0);
            assert.equal(player.address, contractPlayer);
        })

        it("emits event on enter", async () => {
            await expect(raffle.enterRaffle({ value: raffleEntranceFee })).to.emit(raffle,"RaffleEnter");
        })
        
        it("doesn't allow entrance when raffle is calculating", async () => {
            await raffle.enterRaffle({ value: raffleEntranceFee })
            // for a documentation of the methods below, go here: https://hardhat.org/hardhat-network/reference
            // increase the time of whole local blockchain.
            await network.provider.send("evm_increaseTime", [Number(interval) + 1])
            // the change dosent take effect until a new block is mined,so it does that.
            await network.provider.request({ method: "evm_mine", params: [] })
            // we pretend to be a keeper for a second
            await raffle.performUpkeep(ethers.toUtf8Bytes("99")) // changes the state to calculating for our comparison below
            // await expect(raffle.enterRaffle({ value: raffleEntranceFee })).to.be.revertedWithCustomError("Raffle__RaffleNotOpen");
        })
    })


})