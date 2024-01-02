// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

// import "./console.sol";

interface IWondersToken {
    function isApprovedForAll(address owner, address operator) external;

    function safeTransferFrom(address from, address to, uint256 id) external;
}

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

struct Config {
    bool enabled;
    uint128 start;
    uint128 end;
    bytes32 merkleRoot;
    uint16 earnedPerWonder;
    //
    uint256 ethBoxPrice;
    uint256 bpxBoxPrice;
}

contract Claim is Ownable, ReentrancyGuard {
    address public wondersToken;
    address public boxesToken;
    address public bpxToken;
    address public banker;

    mapping(address => uint64) private _boxesEarned;
    mapping(address => uint64) private _allowlistBoxesMinted;
    mapping(address => uint64) private _wondersClaimed;

    uint256 private _nextWonderID = 0;
    uint256 private _maxWonderID = 5000;

    Config private _cfg;

    function setWondersTokenAddress(address addr) public onlyOwner {
        wondersToken = addr;
    }

    function setBoxesTokenAddress(address addr) public onlyOwner {
        boxesToken = addr;
    }

    function setBPXTokenAddress(address addr) public onlyOwner {
        bpxToken = addr;
    }

    function setBankerAddress(address addr) public onlyOwner {
        banker = addr;
    }

    function setClaimEnabled(bool v) public onlyOwner {
        _cfg.enabled = v;
    }

    function setClaimConfig(
        uint128 start,
        uint128 end,
        bytes32 root,
        uint16 earnedBoxesPerWonder
    ) public onlyOwner {
        _cfg.start = start;
        _cfg.end = end;
        _cfg.merkleRoot = root;
        _cfg.earnedPerWonder = earnedBoxesPerWonder;
    }

    function setBoxPrices(uint256 ethPrice, uint256 bpxPrice) public onlyOwner {
        _cfg.ethBoxPrice = ethPrice;
        _cfg.bpxBoxPrice = bpxPrice;
    }

    function setMaxTokenID(uint256 max) public onlyOwner {
        _maxWonderID = max;
    }

    function config() public view returns (Config memory) {
        return _cfg;
    }

    function wondersClaimed(address owner) public view returns (uint64) {
        return _wondersClaimed[owner];
    }

    function earnedBoxes(address dest) public view returns (uint64) {
        return _boxesEarned[dest];
    }

    function nextWonderID() public view returns (uint256) {
        return _nextWonderID;
    }

    function devclaim(address dest, uint256 wonders) public onlyOwner {
        require(
            _nextWonderID + wonders <= _maxWonderID,
            "Claim exceeds supply."
        );

        for (uint256 i = 0; i < wonders; i++) {
            IWondersToken(wondersToken).safeTransferFrom(
                wondersToken,
                dest,
                _nextWonderID + i
            );
        }

        _nextWonderID += wonders;
    }

    function claim(
        address dest,
        uint64 wonders,
        uint64 limit,
        bytes32[] calldata proof
    ) public {
        return claimWithBoxes(dest, wonders, 0, limit, proof);
    }

    function claimWithBoxes(
        address dest,
        uint64 wonders,
        uint64 boxes,
        uint64 limit,
        bytes32[] calldata proof
    ) public payable nonReentrant {
        require(_cfg.enabled, "Claim is not active.");
        require(
            block.timestamp >= _cfg.start && block.timestamp < _cfg.end,
            "Claim window is not open."
        );
        require(wonders <= 20, "Can only claim up to 20 at a time.");
        require(
            _nextWonderID + wonders <= _maxWonderID,
            "Claim exceeds supply."
        );

        bytes32 leaf = keccak256(abi.encodePacked(dest, limit));
        require(
            MerkleProof.verify(proof, _cfg.merkleRoot, leaf),
            "Address not on allowlist."
        );
        require(
            wonders + _wondersClaimed[dest] <= limit,
            "Claim exceeds limit."
        );

        uint64 boxesEarned = uint64(wonders) * _cfg.earnedPerWonder;
        if (boxes > 0) {
            IBox boxesContract = IBox(boxesToken);

            require(
                _boxesEarned[dest] + boxesEarned >= boxes,
                "Not enough boxes earned."
            );

            validateAndAcceptPayment(boxes);

            boxesContract.mint(dest, boxes);
        }

        if (boxesEarned != boxes) {
            _boxesEarned[dest] = uint64(
                int64(_boxesEarned[dest]) + int64(boxesEarned) - int64(boxes)
            );
        }

        _wondersClaimed[dest] += wonders;
        for (uint256 i = 0; i < wonders; i++) {
            IWondersToken(wondersToken).safeTransferFrom(
                wondersToken,
                dest,
                _nextWonderID + i
            );
        }

        _nextWonderID += wonders;
    }

    function buyEarnedBoxes(
        address dest,
        uint16 boxes
    ) public payable nonReentrant {
        IBox boxesContract = IBox(boxesToken);

        require(_cfg.enabled, "Claim is not active.");
        require(
            block.timestamp >= _cfg.start && block.timestamp < _cfg.end,
            "Claim window is not open."
        );

        require(boxes > 0, "Must buy at least one box.");

        require(_boxesEarned[dest] >= boxes, "Not enough boxes earned.");

        validateAndAcceptPayment(boxes);

        _boxesEarned[dest] -= boxes;

        boxesContract.mint(dest, boxes);
    }

    receive() external payable {}

    function validateAndAcceptPayment(uint64 boxes) internal {
        IBPX bpxContract = IBPX(bpxToken);

        if (msg.value > 0) {
            require(
                msg.value == boxes * _cfg.ethBoxPrice,
                "Invalid ETH amount sent."
            );
        } else {
            require(
                bpxContract.balanceOf(_msgSender()) >= boxes * _cfg.bpxBoxPrice,
                "Not enough BPX."
            );
            require(
                bpxContract.allowance(_msgSender(), address(this)) >=
                    boxes * _cfg.bpxBoxPrice,
                "Not enough BPX allowed."
            );
        }

        if (msg.value > 0) {
            (bool sent, ) = banker.call{value: msg.value}("");
            require(sent, "ETH not sent.");
        } else {
            bpxContract.transferFrom(
                _msgSender(),
                banker,
                boxes * _cfg.bpxBoxPrice
            );
        }
    }
}
