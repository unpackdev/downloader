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

contract EVOWAREWhitelistSaleContract is Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 729;
    uint256 public immutable maxWhitelistAmount = 288;
    uint256 public immutable maxWhitelistPerAddressAmount = 1;
    uint256 public constant whitelistSalePrice = 0.69 ether;

    // used to validate whitelists
    bytes32 public whitelistMerkleRoot;

    // set time
    uint64 public immutable whitelistStartTime = 1647684000;
    uint64 public immutable whitelistEndTime = 1647770400;

    mapping(address => uint256) public whitelistMinted;
    uint256 public whitelistMintedAmount;

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

    modifier checkWhitelistTime() {
        require(
            block.timestamp >= uint256(whitelistStartTime) &&
                block.timestamp <= uint256(whitelistEndTime),
            "Outside whitelist round hours"
        );
        _;
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
            "EVOWARE is already exceed max mint amount by this wallet"
        );
        EVOWARE tokenAttribution = EVOWARE(EVOWARETokenAddress);
        tokenAttribution.mint(0, n, msg.sender);
        whitelistMinted[msg.sender] += n;
        whitelistMintedAmount += n;
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
}
