// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./MerkleProof.sol";
import "./IERC20.sol";
import "./AggregatorV3Interface.sol";
import "./HodlerNft.sol";
import "./console.sol";
//

uint256 constant WAD = 1e18;

contract Minter {
    AggregatorV3Interface public immutable priceFeed;
    ETHodlerNft public immutable token;
    uint256 public totalSupply;
    bytes32 public immutable merkleRoot;
    IERC20 public immutable weth;
    IERC20 public immutable stETH;
    uint256 public immutable deadline;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    event Claimed(address indexed to, uint256 index);

    constructor(
        address chainlinkOracle,
        address _token,
        bytes32 _merkleRoot,
        address _weth,
        address _stETH,
        uint256 _deadline
    ) {
        token = ETHodlerNft(_token);
        priceFeed = AggregatorV3Interface(chainlinkOracle);
        merkleRoot = _merkleRoot;
        weth = IERC20(_weth);
        stETH = IERC20(_stETH);
        deadline = _deadline;
    }

    function claim() external {
        require(
            block.timestamp > deadline,
            "CMP" // Cant Mint during Priority minting"
        );
        _mint(msg.sender);
    }

    function claimMerkle(
        uint256 index,
        uint256 salt,
        bytes32[] calldata merkleProof
    ) external {
        require(!isClaimed(index), "TAM"); // TAM: Token is already mined.

        address account = msg.sender;

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, salt));
        require(
            merkleProof.length > 0 &&
                MerkleProof.verify(merkleProof, merkleRoot, node),
            "IP" // Invalid proof.
        );

        // Mark it claimed and send the token.
        _setClaimed(index);
        _mint(account);
    }

    function isClaimAllowed() public view returns (bool) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (uint256(price) / 1e8) > totalSupply;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function checkAccountHasETH() public view returns (bool) {
        uint256 balance = weth.balanceOf(msg.sender) +
            stETH.balanceOf(msg.sender) +
            address(msg.sender).balance;
        return balance > WAD;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function _mint(address account) internal {
        require(
            checkAccountHasETH(),
            "NEB" // Not enough balance: You should have at least 1 ETH of your account
        );
        require(isClaimAllowed(), "ATM"); // All Tokens are Minted
        token.mint(account, totalSupply);
        emit Claimed(account, totalSupply);
        totalSupply++;
    }
}
