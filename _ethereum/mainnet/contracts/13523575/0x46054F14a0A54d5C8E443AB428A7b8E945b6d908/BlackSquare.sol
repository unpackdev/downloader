// SPDX-License-Identifier: UNLICENSED
// Copyright 2021; All rights reserved
// Author: 0x99c520ed5a5e57b2128737531f5626d026ea39f20960b0e750077b9768543949
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721Common.sol";
import "./BlackSquareRandomAttributes.sol";
import "./base64.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract BlackSquare is ERC721Common, ReentrancyGuard {
    using Base64 for string;
    
    /// @notice Constants defining numbers and prices of tokens.
    uint256 immutable public MAX_TOKENS;
    uint256 constant public MINT_PRICE = 0.1 ether;
    uint256 constant public MAX_PER_ADDRESS = 10;

    /// @notice An instance of RandomAttributes.sol responsible for allocating
    /// metadata attributes after the call to setEntropy().
    BlackSquareRandomAttributes immutable public attrs;

    /// @notice An escrow contract to split revenues.
    PaymentSplitter public paymentSplitter;

    constructor(
        string memory name,
        string memory symbol,
        address openSeaProxyRegistry,
        uint256 maxTokens,
        address payable _paymentSplitter
    )
        ERC721Common(name, symbol, openSeaProxyRegistry)
    {
        attrs = new BlackSquareRandomAttributes(maxTokens);
        paymentSplitter = PaymentSplitter(_paymentSplitter);
        MAX_TOKENS = maxTokens;
    }

    /// @notice Tracks the number of tokens already minted by an address,
    /// regardless of transferring out.
    mapping(address => uint) public minted;

    /// @notice Mint the specified number of tokens to the sender.
    /// @dev Reduces n if the origin or sender has already minted tokens or if
    // the total supply is insufficient. The cost is then calculated and the
    /// excess is reimbursed. Although it's possible for someone to set up
    /// multiple wallets, this was a minimal requirement included in the spec.
    function safeMint(uint256 n) nonReentrant payable public {
        /**
         * ##### CHECKS
         */
        n = _capExtra(n, msg.sender, "Sender limit");
        // Enforce the limit even if proxying through a contract.
        if (msg.sender != tx.origin) {
            n = _capExtra(n, tx.origin, "Origin limit");
        }
        
        uint256 nextTokenId = totalSupply();
        uint256 left = MAX_TOKENS - nextTokenId;
        require (left > 0, "Sold out");
        if (n > left) {
            n = left;
        }

        uint256 cost = n * MINT_PRICE;
        require(msg.value >= cost, "Insufficient payment");

        /**
         * ##### EFFECTS
         */
        minted[msg.sender] += n;
        if (msg.sender != tx.origin) {
            minted[tx.origin] += n;
        }

        for (uint end = nextTokenId + n; nextTokenId < end; nextTokenId++) {
            _safeMint(msg.sender, nextTokenId);
        }

        /**
         * ##### INTERACTIONS (also nonReentrant)
         */
        payable(paymentSplitter).transfer(cost);
        
        if (msg.value > cost) {
            address payable reimburse = payable(msg.sender);
            reimburse.transfer(msg.value - cost);
        }
    }

    /// @notice Changes the address of the PaymentSplitter contract.
    function setPaymentSplitter(address payable _paymentSplitter) onlyOwner external {
        paymentSplitter = PaymentSplitter(_paymentSplitter);
    }

    /// @notice Returns min(n, max(extra tokens addr can mint)).
    function _capExtra(uint256 n, address addr, string memory zeroMsg) internal view returns (uint256) {
        uint256 extra = MAX_PER_ADDRESS - minted[addr];
        require (extra > 0, zeroMsg);
        if (n > extra) {
            return extra;
        }
        return n;
    }

    /// @notice Sets the entropy source for deciding on random attributes.
    /// @dev This MUST be set after all tokens are minted so minters can't cheat
    /// the system, and MUST also be a value out of our control; in the absence
    /// of a VRF, a good choice is the block hash of the first block after final
    /// token mint.
    function setEntropy(bytes32 entropy) onlyOwner external {
        attrs.setEntropy(entropy);
    }

    /// @notice Returns the value passed to setEntropy() or 0 if not already
    /// called.
    function getEntropy() external view returns (bytes32) {
        return attrs.getEntropy();
    }

    /// @notice Exposes RandomAttributes._newTieredTrait().
    function newTieredTrait(uint index, RandomAttributes.TieredTrait memory trait) onlyOwner public {
        attrs._newTieredTrait(index, trait);
    }

    /// @notice Exposes RandomAttributes._newAllocatedTrait(), allowing for
    /// multiple allocations to be passed in a single call.
    function newAllocatedTraits(uint firstIndex, RandomAttributes.Allocated[] memory alloc) onlyOwner public {
        for (uint i = 0; i < alloc.length; i++) {
            attrs._newAllocatedTrait(firstIndex+i, alloc[i]);
        }
    }

    /// @notice Returns the number equivalent to a basis point (0.01%) as used
    /// by RandomAttributes.
    function basisPoint() external view returns (uint256) {
        return attrs.BASIS_POINT();
    }

    /// @notice Returns the token's metadata. This will change after the call to
    /// setEntropy(), after which it will be immutable.
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require (ERC721._exists(tokenId), "Token doesn't exist");

        bytes memory json = abi.encodePacked(
            '{',
                '"name": "', name(), ' #', Strings.toString(tokenId), '",',
                '"image": "data:image/svg+xml;base64,',
                    'PHN2ZyB3aWR0aD0iMTQwMCIgaGVpZ2h0PSIxNDAwIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcv',
                    'MjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIj48cmVj',
                    'dCB3aWR0aD0iMTQwMCIgaGVpZ2h0PSIxNDAwIiBzdHlsZT0iZmlsbDpyZ2IoMCwwLDApO3N0cm9r',
                    'ZS13aWlkdGg6MCIgLz48L3N2Zz4=",',
                '"attributes": ['
        );

        if (attrs.entropySet()) {
            json = abi.encodePacked(
                json,
                '{"value": "The world is better with you in it"}',
                attrs._attributesOf(tokenId)
            );
        } else {
            json = abi.encodePacked(json, '{"value": "AWGMI?"}');
        }

        json = abi.encodePacked(
            json,
                ']',
            '}'
        );

        return string(abi.encodePacked(
            "data:application/json;base64,", Base64.encode(json)
        ));
    }
}