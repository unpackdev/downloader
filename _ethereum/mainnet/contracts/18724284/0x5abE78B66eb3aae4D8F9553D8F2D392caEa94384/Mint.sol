// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

interface IBox {
    function mint(address to, uint256 quantity) external;

    function totalMinted() external view returns (uint256);

    function maxSupply() external view returns (uint256);
}

interface IBPX {
    function balanceOf(address _owner) external view returns (uint256 balance);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
}

contract Mint is Ownable, ReentrancyGuard {
    address public boxesToken;
    address public bpxToken;
    address public banker;

    bytes32 private thankYouMerkleRoot;
    bool private thankYouEnabled;

    bytes32 private allowlistMerkleRoot;
    bool private allowlistEnabled;

    bool private publicEnabled;

    uint256 private ethBoxPrice;
    uint256 private bpxBoxPrice;

    mapping(bytes32 => bool) _freeLeavesUsed;
    mapping(address => uint256) _totalMintsUsed;

    uint64 private perTransactionLimit = 6;

    function setBoxesTokenAddress(address addr) public onlyOwner {
        boxesToken = addr;
    }

    function setBPXTokenAddress(address addr) public onlyOwner {
        bpxToken = addr;
    }

    function setBankerAddress(address addr) public onlyOwner {
        banker = addr;
    }

    function setBoxPrices(uint256 eth, uint256 bpx) public onlyOwner {
        ethBoxPrice = eth;
        bpxBoxPrice = bpx;
    }

    function setPerTransactionLimit(uint64 num) public onlyOwner {
        perTransactionLimit = num;
    }

    function setEnabled(
        bool thankYou_,
        bool allowlist_,
        bool public_
    ) public onlyOwner {
        thankYouEnabled = thankYou_;
        allowlistEnabled = allowlist_;
        publicEnabled = public_;
    }

    function enabled() public view returns (bool, bool, bool) {
        return (thankYouEnabled, allowlistEnabled, publicEnabled);
    }

    function setMerkleRoots(
        bytes32 thankYou,
        bytes32 allowlist
    ) public onlyOwner {
        thankYouMerkleRoot = thankYou;
        allowlistMerkleRoot = allowlist;
    }

    function leafUsed(address dest, uint64 boxes) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(dest, boxes));
        return _freeLeavesUsed[leaf];
    }

    function minted(address addr) public view returns (uint256) {
        return _totalMintsUsed[addr];
    }

    function totalMinted() external view returns (uint256) {
        return IBox(boxesToken).totalMinted();
    }

    function supplyLimit() external view returns (uint256) {
        return IBox(boxesToken).maxSupply();
    }

    function thankYouMint(
        address dest,
        uint64 boxes,
        bytes32[] calldata proof
    ) public {
        IBox boxesContract = IBox(boxesToken);

        require(
            thankYouEnabled && thankYouMerkleRoot != bytes32(0),
            "Claim is not active."
        );
        require(boxes > 0, "Must buy at least one box.");

        bytes32 leaf = keccak256(abi.encodePacked(dest, boxes));
        require(!_freeLeavesUsed[leaf], "Mint already used.");

        require(
            MerkleProof.verify(proof, thankYouMerkleRoot, leaf),
            "Address not on allowlist."
        );

        _freeLeavesUsed[leaf] = true;

        boxesContract.mint(dest, boxes);
    }

    function mint(
        address dest,
        uint64 boxes,
        uint64 limit,
        bytes32[] calldata proof
    ) public payable nonReentrant {
        IBox boxesContract = IBox(boxesToken);

        require(
            allowlistEnabled && allowlistMerkleRoot != bytes32(0),
            "Claim is not active."
        );
        require(boxes > 0, "Must buy at least one box.");

        bytes32 leaf = keccak256(abi.encodePacked(dest, limit));

        require(
            MerkleProof.verify(proof, allowlistMerkleRoot, leaf),
            "Address not on allowlist."
        );

        require(
            _totalMintsUsed[dest] + boxes <= limit,
            "Mint exceeds wallet limit."
        );

        capturePayment(boxes);

        _totalMintsUsed[dest] += boxes;

        boxesContract.mint(dest, boxes);
    }

    function publicMint(
        address dest,
        uint64 boxes
    ) public payable nonReentrant {
        IBox boxesContract = IBox(boxesToken);

        require(publicEnabled, "Claim is not active.");
        require(boxes > 0, "Must buy at least one box.");

        require(
            boxes <= perTransactionLimit,
            "Mint exceeds per transaction limit."
        );

        capturePayment(boxes);

        _totalMintsUsed[dest] += boxes;

        boxesContract.mint(dest, boxes);
    }

    function capturePayment(uint64 boxes) internal {
        IBPX bpxContract = IBPX(bpxToken);

        if (msg.value > 0) {
            require(
                msg.value == uint256(boxes) * ethBoxPrice,
                "Invalid ETH amount sent."
            );
            (bool sent, ) = banker.call{value: msg.value}("");
            require(sent, "ETH not sent.");

            return;
        }

        require(
            bpxContract.balanceOf(_msgSender()) >= uint256(boxes) * bpxBoxPrice,
            "Not enough BPX."
        );

        require(
            bpxContract.allowance(_msgSender(), address(this)) >=
                uint256(boxes) * bpxBoxPrice,
            "Not enough BPX allowed."
        );

        bpxContract.transferFrom(
            _msgSender(),
            banker,
            uint256(boxes) * bpxBoxPrice
        );
    }
}
