// SPDX-License-Identifier: MIT
//  @@@@@@@@@@@@@@@@@@@@@@@@@        &   &@@@@@@@@@@@@@@@@@@@@@@@@@@    #@@@@     #@@@@@@@,       &@@@@@@@@@@@@@@@@@@@@@@@@@@/       /@@@@@@@/             &
//  %%%%%%%%%%%%%%%%%%%%%%&@@@&    @@@   #%%%%%%%%%&@@@%%%%%%%%%%%    &@@@@    &@@@@@&&@@@@@@.    #%%%%%%%%%%%%%%%%%%%%%%%%%%*    /@@@@@@%@@@@@@(          &@@.
//                         @@@@   #@@@             ,@@@             &@@@&    @@@@%        (@@@/                                  %@@@,        @@@@#        &@@#
//  %@@@@@@@@@@@@@@@@@@@@@@@@@    #@@@             ,@@@           @@@@%   .@@@@#           %@@&   *@@@@@@@@@@@@@@@@@@@@@@@@@@/  .@@@*           @@@@%      &@@#
//  @@@*                   /@@@   #@@@             ,@@@         @@@@#   .@@@@(             %@@&   &@@&                          .@@@*             &@@@&    &@@#
//   @@,  .@@@@@@@@@@@@@@@@@@@&   #@@@             ,@@@      .@@@@#   ,@@@@/               %@@&   #@@@@@@@@@@@@@@@@@@@@@@@@@@/  .@@@*               %@@@@  &@@#
//     ,  .@@@@@@@@@@@@@@@@@,     #@@@             ,@@@    .@@@@(   *@@@@*                 %@@&     #@@@@@@@@@@@@@@@@@@@@@@@@/  .@@@*                 #@@@@&@@#
pragma solidity ^0.8.4;
import "./IERC20.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

abstract contract EVOWARE {
    function mint(
        uint256 tknId,
        uint256 n,
        address to
    ) public payable virtual returns (uint256);
}

contract EVOWAREAuctionWhitelistSale is Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 729;
    //whitelist
    uint256 public maxWhitelistAmount = 21;
    uint256 public immutable maxWhitelistPerAddressAmount = 1;
    uint256 public constant whitelistSalePrice = 0.69 ether;
    //auction
    uint256 public auctionMaxMintAmount = 371;
    uint256 public lastAuctionPrice = 2 ether;
    uint256 public constant auctionStartPrice = 2 ether;
    uint256 public constant auctionMinPrice = 0.8 ether;
    uint256 public constant auctionRate = 0.1 ether;
    uint256 public constant autcionTimeRate = 5 * 1 minutes;
    // used to validate whitelists
    bytes32 public whitelistMerkleRoot;

    // set time
    uint64 public immutable whitelistStartTime = 1648274400;
    uint64 public immutable whitelistEndTime = 1648310400;

    uint64 public immutable auctionStartTime = 1648360800;
    uint64 public immutable auctionEndTime = 1648396800;

    mapping(address => uint256) public whitelistMinted;
    uint256 public whitelistMintedAmount;
    uint256 public auctionMintedAmount;

    address EVOWARETokenAddress;
    address withdrawAddress;

    constructor() {}

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier canWhitelistMint(uint256 numberOfTokens) {
        uint256 ts = whitelistMintedAmount;
        require(
            ts + numberOfTokens <= maxWhitelistAmount,
            "Purchase would exceed max whitelist round tokens"
        );
        _;
    }
    modifier canAuctionMint(uint256 n) {
        uint256 ts = auctionMintedAmount;
        require(
            ts + n <= auctionMaxMintAmount,
            "Purchase would exceed max auction mint amount"
        );
        _;
    }
    modifier checkWhitelistTime() {
        require(
            block.timestamp >= uint256(whitelistStartTime) &&
                block.timestamp <= uint256(whitelistEndTime),
            "Outside whitelist round hours"
        );
        _;
    }
    modifier checkAuctionTime() {
        require(
            block.timestamp >= uint256(auctionStartTime) &&
                block.timestamp <= uint256(auctionEndTime),
            "Outside autcion round hours"
        );
        _;
    }

    function mintAuction()
        public
        payable
        canAuctionMint(1)
        checkAuctionTime
        nonReentrant
    {
        uint256 price = getAuctionPrice();
        if (price != lastAuctionPrice) {
            lastAuctionPrice = price;
        }
        require(msg.value >= price, "Incorrect ETH value sent");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
        EVOWARE tokenAttribution = EVOWARE(EVOWARETokenAddress);
        tokenAttribution.mint(0, 1, msg.sender);
        ++auctionMintedAmount;
    }

    function mintWhitelist(uint256 n, bytes32[] calldata merkleProof)
        public
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        isCorrectPayment(whitelistSalePrice, n)
        canWhitelistMint(n)
        checkWhitelistTime
        nonReentrant
    {
        require(
            whitelistMinted[msg.sender] + n <= maxWhitelistPerAddressAmount,
            "EVOWARE is already exceed max mint amount by this wallet at whitelist round"
        );
        EVOWARE tokenAttribution = EVOWARE(EVOWARETokenAddress);
        tokenAttribution.mint(0, n, msg.sender);
        whitelistMinted[msg.sender] += n;
        whitelistMintedAmount += n;
    }

    function getAuctionPrice() public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - auctionStartTime;
        uint256 discount = auctionRate * (timeElapsed / autcionTimeRate);
        if (discount > auctionStartPrice - auctionMinPrice) {
            discount = auctionStartPrice - auctionMinPrice;
        }
        uint256 price = auctionStartPrice - discount;
        return price;
    }

    function withdraw() public {
        require(msg.sender == withdrawAddress, "not withdrawAddress");
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public {
        require(msg.sender == withdrawAddress, "not withdrawAddress");
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function setEVOWARETokenAddress(address newAddress) public onlyOwner {
        EVOWARETokenAddress = newAddress;
    }

    function setWithdrawAddress(address newAddress) public onlyOwner {
        withdrawAddress = newAddress;
    }

    function setAuctionMaxMintAmount(uint256 newAmount) public onlyOwner {
        auctionMaxMintAmount = newAmount;
    }

    function setWhitelistMaxMintAmount(uint256 newAmount) public onlyOwner {
        maxWhitelistAmount = newAmount;
    }
}
