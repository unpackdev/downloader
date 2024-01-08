// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

import "./VRFConsumerBase.sol";
import "./NakamotOsERC721.sol";
import "./ERC20.sol";


contract NakamotOsERC20 is ERC20, VRFConsumerBase {
    using SafeMathChainlink for uint256;

    event Burn(address indexed burner, uint256 amount);

    mapping(address => uint256) public burnedTokens;

    NakamotOsERC721 public nftToken;
    uint256 public maxNFTSupply;
    uint256 public ONE = 10**18;

    bytes32 private keyHash;

    uint256 public lottoBlock;
    bool private hasLotteryStarted;

    uint256 public ticketCount;
    mapping(uint256 => address) public ticketToOwner;
    mapping(address => uint256) public ownerTicketCount;

    uint256 private fee;

    uint256 public randomNumber;

    bool public hasRandomNumber = false;
    bool public hasMintedNFTs = false;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply,
        address bagHolder,
        address nftTokenAddress_,
        uint256 maxNFTSupply_,
        uint256 blocksTilLotto,
        bytes32 keyHash_,
        address vrfCoordinator,
        address linkToken,
        uint256 linkFee
    ) public ERC20(name_, symbol_) VRFConsumerBase(vrfCoordinator, linkToken) {
        _mint(bagHolder, maxSupply);
        nftToken = NakamotOsERC721(nftTokenAddress_);
        maxNFTSupply = maxNFTSupply_;
        keyHash = keyHash_;
        lottoBlock = block.number + blocksTilLotto;
        hasLotteryStarted = false;

        fee = linkFee;
        ticketCount = 0;
    }

    // add burner to an enumerable set
    // only add to enumberable set if less than lotto block
    function burn(uint256 amount) external returns (bool) {
        _burn(_msgSender(), amount);
        emit Burn(_msgSender(), amount);


        // burned token mapping so we can easily see how many tokens an address has burned
        burnedTokens[_msgSender()] = burnedTokens[_msgSender()].add(amount);

        if (block.number < lottoBlock) {
            uint256 ticketsCreated = amount.div(ONE);
            for (uint256 i = 0; i < ticketsCreated; i++) {
                ticketToOwner[ticketCount] = _msgSender();
                ticketCount = ticketCount.add(1);
            }
            ownerTicketCount[_msgSender()] = ownerTicketCount[_msgSender()].add(ticketsCreated);
        }

        return true;
    }

    // function for lotto call after block
    function startLottery(uint256 userProvidedSeed) public returns (bytes32 requestId) {
        require(hasLotteryStarted == false, "The lottery has not started yet");
        require(block.number >= lottoBlock, "The lottery has already started");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay the fee");
        require(ticketCount > 0, "Must be tickets to start lottery");

        hasLotteryStarted = true;
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    function fulfillRandomness(bytes32 /* requestId */, uint256 randomness) internal override {
        randomNumber = randomness;
        hasRandomNumber = true;
    }

    function mintNFTs() external {
        require(hasRandomNumber, "Random Numbers have not been set");
        require(!hasMintedNFTs, "NFTs already minted");

        uint256[] memory randomNumbers = expand(randomNumber);

        for (uint256 index = 0; index < randomNumbers.length; index++) {
            uint256 randomTicket = randomNumbers[index].mod(ticketCount);
            address ticketOwner = ticketToOwner[randomTicket];
            nftToken.mint(ticketOwner, 1);
        }

        hasMintedNFTs = true;
    }

    // function copied from https://docs.chain.link/docs/get-a-random-number#making-the-most-out-of-vrf
    function expand(uint256 randomValue) public view returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](maxNFTSupply);
        for (uint256 i = 0; i < maxNFTSupply; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }
}
