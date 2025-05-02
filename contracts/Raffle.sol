// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;






// random num generator
import "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";


// automation
import "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";




// custom errors
error Raffle_SendMoreETHToEnter();
error Raffle_UpKeepNotNeeded(uint256 currBalance,uint256 numPlayers,uint256 raffleState)



// Contract
contract Raffle is VRFConsumerBaseV2Plus {

    // Type declarations
    enum RaffleState{
        OPEN, // 0
        CALCULATING // 1
    }


    // State variables
    uint256 private immutable i_entranceFee;
    address payable[] private players;
    bytes32 public s_keyHash;
    uint256 public s_subscriptionId;
    uint16 public requestConfirmations = 3;
    uint32 public callbackGasLimit = 40000;
    uint32 public numWords = 1;

    // Lottery variables
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp

    RaffleState private s_raffleState;




    // Events
    event RaffleEnter(address indexed player);
    event RaffleWinner(uint256 requestId);




    // Constructor
    constructor(uint256 _i_entranceFee,address vrfCoordinator) VRFConsumerBaseV2Plus(vrfCoordinator){
        i_entranceFee=_i_entranceFee;
        s_raffleState=RaffleState.OPEN;
        s_lastTimeStamp=block.timestamp;
    }






    // Entering in the raffle 
    // with this function anyone can pay an entrance fee in order to join the program.
    function enterRaffle() public payable{
        if(msg.value<i_entranceFee){
            revert Raffle_SendMoreETHToEnter();
        }
        players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }






    // Getting random number

    function requestRandomWinner() public{
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        emit RaffleWinner(requestId);
    }



    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexOfWinnter = (randomWords[0] % 20) + 1;
        address payable recentWinner=players[indexOfWinnter];
    }






    // automation related functions

    function checkUpkeep(bytes memory) public view override returns (bool upkeepNeeded, bytes memory){
        bool isOpen=RaffleState.OPEN==s_raffleState;
        bool timePassed=((block.timestamp-s_lastTimeStamp)>i_interval);
        bool hasPlayers=players.length>0;
        bool hasBalance=address(this).balance>0;
        upKeepNeeded=(isOpen && timePassed && hasPlayers && hasBalance);

        return (upKeepNeeded,"0x0");
    }

    function performUpKeep(bytes calldata) external override{
        (bool upKeepNeeded,)=checkUpKeep("");
        if(!upKeepNeeded){
            revert Raffle_UpKeepNotNeeded(address(this).balance,players.length,uint256(s_raffleState));
        }

        s_raffleState=

    }


}