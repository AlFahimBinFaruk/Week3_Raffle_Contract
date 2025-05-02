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
error Raffle_UpKeepNotNeeded(uint256 currBalance,uint256 numPlayers,uint256 raffleState);
error Raffle__RaffleNotOpen();
error Raffle__TransferFailed();




// Contract
contract Raffle is VRFConsumerBaseV2Plus,AutomationCompatibleInterface {

    // Type declarations
    enum RaffleState{
        OPEN, // 0
        CALCULATING // 1
    }





    // State variables

    // Chainlink VRF variables.
    bytes32 public immutable i_keyHash;
    uint256 public immutable i_subscriptionId;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public immutable i_callbackGasLimit;
    uint32 public constant NUMWORDS = 1;



    // Lottery variables.
    address payable[] private s_players;
    uint256 private immutable i_interval;
    uint256 private immutable i_entranceFee;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;




    // Events
    event RaffleEnter(address indexed player);
    event RaffleWinner(uint256 requestId);
    event WinnerPicked(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);




    // Constructor
    constructor(
        address vrfCoordinator,
        uint256 _i_entranceFee,
        bytes32 _keyHash,
        uint256 _subscriptionId,
        uint32 _callbackGasLimit,
        uint256 _i_interval
        ) VRFConsumerBaseV2Plus(vrfCoordinator){
        i_entranceFee=_i_entranceFee;
        s_raffleState=RaffleState.OPEN;
        s_lastTimeStamp=block.timestamp;
        i_keyHash=_keyHash;
        i_subscriptionId=_subscriptionId;
        i_callbackGasLimit=_callbackGasLimit;
        i_interval=_i_interval;
    }






    // Entering in the raffle 
    // with this function anyone can pay an entrance fee in order to join the program.
    function enterRaffle() public payable{
        if(msg.value<i_entranceFee){
            revert Raffle_SendMoreETHToEnter();
        }
        if(s_raffleState!=RaffleState.OPEN){
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }






    // automation related functions
    function checkUpkeep(bytes memory) public view override returns (bool upkeepNeeded, bytes memory){
        bool isOpen=RaffleState.OPEN==s_raffleState;
        bool timePassed=((block.timestamp-s_lastTimeStamp)>i_interval);
        bool hasPlayers=s_players.length>0;
        bool hasBalance=address(this).balance>0;
        bool upKeepNeeded=(isOpen && timePassed && hasPlayers && hasBalance);

        return (upKeepNeeded,"0x0");
    }



    function performUpkeep(bytes calldata) external override{
        (bool upKeepNeeded,)=checkUpkeep("");
        if(!upKeepNeeded){
            revert Raffle_UpKeepNotNeeded(address(this).balance,s_players.length,uint256(s_raffleState));
        }

        s_raffleState=RaffleState.CALCULATING;
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUMWORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        emit RequestedRaffleWinner(requestId);
    }





    // Getting random number to figure out the winner.
    function fulfillRandomWords(
        uint256,
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexOfWinnter = (randomWords[0] % s_players.length);
        address payable recentWinner=s_players[indexOfWinnter];
        s_recentWinner=recentWinner;

        //resetting
        s_players=new address payable[](0);
        s_raffleState=RaffleState.OPEN;
        s_lastTimeStamp=block.timestamp;

        // making the payment to winner.
        (bool success,)=recentWinner.call{value:address(this).balance}("");
        
        if(!success){
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);

    }





    // Getter functions
    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }


}