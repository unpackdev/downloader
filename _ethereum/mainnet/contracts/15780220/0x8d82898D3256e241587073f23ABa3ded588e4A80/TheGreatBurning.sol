// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// Discord: https://discord.gg/5vAWb9yy
// Twitter: https://twitter.com/PocketBones
// PocketBones etherscan: https://etherscan.io/address/0xeab79a9468321c0c865b33eae013e573c9d05737#writeContract

// Steps to burn:
// 1. setApprovalForAll -> operator = THIS CONTRACT ADDRESS, approved = 1 (PocketBones etherscan field 11)
// 2. enterRaffle -> tokenIds = whatever bones you want to burn. YOU MUST OWN THEM. ex arg. [0,1,2] (no spacing in between)

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract TheGreatBurning is Ownable, VRFConsumerBaseV2, ReentrancyGuard {
    // ===========================
    // VARIABLES
    // ===========================
    address[] public winners;
    uint256[] public winningNumbers;

    // ===========================
    // CHAINLINK
    // ===========================
    VRFCoordinatorV2Interface public vrfCoordinator;

    bytes32 public vrfKeyHash;
    uint64 public vrfSubscriptionId;
    uint32 public vrfCallbackGasLimit = 150000;
    uint32 public vrfNumWords = 1;
    uint16 public vrfRequestConfirmations = 3;

    // ===========================
    // BONES INTERFACE and dEaD
    // ===========================
    IERC721 public bones = IERC721(0xEAB79a9468321c0c865b33eAE013E573C9d05737);
    address public immutable GRAVEYARD =
        0x000000000000000000000000000000000000dEaD;

    // ===========================
    // CONSTRUCTOR
    // ===========================
    constructor(
        address _vrfCoordinator,
        bytes32 _vrfKeyHash,
        uint64 _vrfSubscriptionId
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        vrfKeyHash = _vrfKeyHash;
        vrfSubscriptionId = _vrfSubscriptionId;
    }

    // ===========================
    // PRIZES
    // ===========================
    struct Prize {
        uint256[] tokenIds;
        address nftAddress;
        bool ethPrize;
    }
    Prize[] public prizes;

    function createPrize(
        uint256[] memory _tokenIds,
        address _nftAddress,
        bool _ethPrize
    ) external onlyOwner {
        Prize memory prize = Prize({
            tokenIds: _tokenIds,
            nftAddress: _nftAddress,
            ethPrize: _ethPrize
        });
        if (!_ethPrize) {
            IERC721 nft = IERC721(_nftAddress);
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                nft.transferFrom(msg.sender, address(this), _tokenIds[i]);
            }
        }
        prizes.push(prize);
    }

    // ===========================
    // RAFFLES
    // ===========================
    struct Raffle {
        uint256 maxEntries;
        uint256 maxEntriesPerWallet;
        uint256 numEntries;
        bool open;
        mapping(uint256 => address) raffleEntries;
        mapping(address => uint256) walletEntries;
    }
    uint256 public numRaffles;
    mapping(uint256 => Raffle) public raffles;

    function setRaffleStatus(uint256 raffleId, bool _open) external onlyOwner {
        Raffle storage raffle = raffles[raffleId];
        raffle.open = _open;
    }

    function createRaffle(uint256 _maxEntries, uint256 _maxEntriesPerWallet)
        external
        onlyOwner
    {
        Raffle storage raffle = raffles[numRaffles++];
        raffle.maxEntries = _maxEntries;
        raffle.maxEntriesPerWallet = _maxEntriesPerWallet;
        raffle.numEntries = 0;
        raffle.open = false;
    }

    function enterRaffle(uint256[] memory tokenIds) external nonReentrant {
        Raffle storage raffle = raffles[numRaffles - 1];
        require(raffle.open, "raffle isn't live");
        require(
            raffle.walletEntries[msg.sender] + tokenIds.length <=
                raffle.maxEntriesPerWallet,
            "exceeded wallet ticket amount"
        );
        require(
            raffle.numEntries + tokenIds.length <= raffle.maxEntries,
            "no more entries"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            bones.transferFrom(msg.sender, GRAVEYARD, tokenIds[i]);
        }
        raffle.numEntries += tokenIds.length;
        raffle.walletEntries[msg.sender] += tokenIds.length;
        raffle.raffleEntries[raffle.numEntries - 1] = msg.sender;
    }

    // ===========================
    // DRAWING WINNERS
    // ===========================
    function selectWinner() public onlyOwner returns (uint256) {
        return (
            vrfCoordinator.requestRandomWords(
                vrfKeyHash,
                vrfSubscriptionId,
                vrfRequestConfirmations,
                vrfCallbackGasLimit,
                vrfNumWords
            )
        );
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        override
    {
        winningNumbers.push(randomWords[0]);
        Raffle storage raffle = raffles[numRaffles - 1];
        uint256 winningEntry = randomWords[0] % (raffle.numEntries - 1);
        while (true) {
            if (raffle.raffleEntries[winningEntry] != address(0)) {
                winners.push(raffle.raffleEntries[winningEntry]);
                return;
            } else winningEntry++;
        }
    }

    function disperseWinnings() external onlyOwner {
        for (uint256 i = 0; i < prizes.length; i++) {
            Prize memory prize = prizes[i];
            if (prize.ethPrize) {
                (bool succ, ) = payable(winners[i]).call{
                    value: address(this).balance
                }("");
                require(succ, "Withdraw failed");
            } else {
                IERC721 nft = IERC721(prize.nftAddress);
                for (uint256 n = 0; n < prize.tokenIds.length; n++) {
                    nft.transferFrom(
                        address(this),
                        winners[i],
                        prize.tokenIds[n]
                    );
                }
            }
        }
    }

    function depositEth() external payable {}

    // ===========================
    // HELPERS and SETTERS
    // ===========================
    function setBones(address addr) external onlyOwner {
        bones = IERC721(addr);
    }

    function setKeyHash(bytes32 _vrfKeyHash) external onlyOwner {
        vrfKeyHash = _vrfKeyHash;
    }

    function setSubscriptionId(uint64 _vrfSubscriptionId) external onlyOwner {
        vrfSubscriptionId = _vrfSubscriptionId;
    }

    function setVRFCoordinator(address _vrfCoordinator) external onlyOwner {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
    }

    function setVRFCallbackLimit(uint32 _vrfCallbackGasLimit)
        external
        onlyOwner
    {
        vrfCallbackGasLimit = _vrfCallbackGasLimit;
    }

    function viewRaffleEntries(uint256 index) public view returns (address) {
        Raffle storage raffle = raffles[numRaffles - 1];
        return raffle.raffleEntries[index];
    }

    function viewEntriesByWallet(address addr) public view returns (uint256) {
        Raffle storage raffle = raffles[numRaffles - 1];
        return raffle.walletEntries[addr];
    }

    function viewTotalEntries() public view returns (uint256) {
        Raffle storage raffle = raffles[numRaffles - 1];
        return raffle.numEntries;
    }

    function viewPrize(uint256 prizeId)
        public
        view
        returns (uint256[] memory, address)
    {
        Prize memory prize = prizes[prizeId];
        return (prize.tokenIds, prize.nftAddress);
    }

    // ===========================
    // FAILSAFE
    // ===========================
    function withdraw() external onlyOwner {
        (bool succ, ) = payable(owner()).call{value: address(this).balance}("");
        require(succ, "Withdraw failed");
    }

    function failSafe(address nftAddress, uint256[] memory tokenIds)
        external
        onlyOwner
    {
        IERC721 nft = IERC721(nftAddress);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            nft.transferFrom(address(this), owner(), tokenIds[i]);
        }
    }
}
