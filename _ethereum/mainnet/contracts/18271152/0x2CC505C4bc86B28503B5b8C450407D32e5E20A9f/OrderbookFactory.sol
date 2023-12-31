// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./AccessControl.sol";
import "./Orderbook.sol";
import "./CloneFactory.sol";
import "./IOrderbookFactory.sol";
import "./Initializable.sol";

interface IERC20 {
    function symbol() external view returns (string memory);
}

contract OrderbookFactory is IOrderbookFactory, Initializable {
    // Orderbooks
    address[] public allPairs;
    /// Address of manager
    address public override engine;
    /// version number of impl
    uint32 public version;
    /// address of order impl
    address public impl;

    error InvalidAccess(address sender, address allowed);
    error PairAlreadyExists(address base, address quote, address pair);
    error SameBaseQuote(address base, address quote);

    constructor() {
    }

    function createBook(
        address base_,
        address quote_
    ) external override returns (address orderbook) {
        if (msg.sender != engine) {
            revert InvalidAccess(msg.sender, engine);
        }

        if (base_ == quote_) {
            revert SameBaseQuote(base_, quote_);
        }

        address pair = _predictAddress(base_, quote_);

        // Check if the address has code
        uint32 size;
        assembly {
            size := extcodesize(pair)
        }

        // If the address has code and it's a clone of impl, revert.
        if (size > 0 || CloneFactory._isClone(impl, pair)) {
            revert PairAlreadyExists(base_, quote_, pair);
        }

        address proxy = CloneFactory._createCloneWithSalt(
            impl,
            _getSalt(base_, quote_)
        );
        IOrderbook(proxy).initialize(
            allPairsLength(),
            base_,
            quote_,
            engine
        );
        allPairs.push(proxy);
        return (proxy);
    }

    function isClone(address vault) external view returns (bool cloned) {
        cloned = CloneFactory._isClone(impl, vault);
    }

    function getBook(uint256 bookId_) external view override returns (address) {
        return allPairs[bookId_];
    }

    function getBookByPair(
        address base,
        address quote
    ) external view override returns (address book) {
        book = _predictAddress(base, quote);
        bool isContractCode;
        assembly {
            // Retrieve the size of the code at the address
            let codeSize := extcodesize(book)
            // Check if the code size is greater than zero
            isContractCode := gt(codeSize, 0)
        }
        return isContractCode ? book : address(0);
    }

    function getPairs(
        uint256 start,
        uint256 end
    ) public view override returns (IOrderbookFactory.Pair[] memory) {
        uint256 last = end > allPairs.length ? allPairs.length : end;
        IOrderbookFactory.Pair[] memory pairs = new IOrderbookFactory.Pair[](
            last - start
        );
        for (uint256 i = start; i < last; i++) {
            (address base, address quote) = IOrderbook(allPairs[i])
                .getBaseQuote();
            pairs[i] = Pair(base, quote);
        }
        return pairs;
    }

    function getPairsWithIds(
        uint256[] memory ids
    ) public view override returns (IOrderbookFactory.Pair[] memory pairs) {
        pairs = new IOrderbookFactory.Pair[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            (address base, address quote) = IOrderbook(allPairs[i])
                .getBaseQuote();
            pairs[i] = Pair(base, quote);
        }
        return pairs;
    }

    function getPairNames(
        uint256 start,
        uint256 end
    ) external view override returns (string[] memory names) {
        IOrderbookFactory.Pair[] memory pairs = getPairs(start, end);
        names = new string[](pairs.length);
        for (uint256 i = 0; i < pairs.length; i++) {
            string memory baseName = IERC20(pairs[i].base).symbol();
            string memory quoteName = IERC20(pairs[i].quote).symbol();
            names[i] = string(abi.encodePacked(baseName, "/", quoteName));
        }
        return names;
    }

    function getPairNamesWithIds(
        uint256[] memory ids
    ) external view override returns (string[] memory names) {
        names = new string[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            (address base, address quote) = IOrderbook(allPairs[i])
                .getBaseQuote();
            string memory baseName = IERC20(base).symbol();
            string memory quoteName = IERC20(quote).symbol();
            names[i] = string(abi.encodePacked(baseName, "/", quoteName));
        }
        return names;
    }

    function getBaseQuote(
        address orderbook
    ) external view override returns (address base, address quote) {
        return IOrderbook(orderbook).getBaseQuote();
    }

    /**
     * @dev Initialize orderbook factory contract with engine address, reinitialize if engine is reset.
     * @param engine_ The address of the engine contract
     */
    function initialize(address engine_) public initializer {
        engine = engine_;
        _createImpl();
    }

    function allPairsLength() public view returns (uint256) {
        return allPairs.length;
    }

    // Set immutable, consistant, one rule for orderbook implementation
    function _createImpl() internal {
        address addr;
        bytes memory bytecode = type(Orderbook).creationCode;
        bytes32 salt = keccak256(abi.encodePacked("orderbook", version));
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        impl = addr;
    }

    function _predictAddress(
        address base_,
        address quote_
    ) internal view returns (address) {
        bytes32 salt = _getSalt(base_, quote_);
        return CloneFactory.predictAddressWithSalt(address(this), impl, salt);
    }

    function _getSalt(
        address base_,
        address quote_
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(base_, quote_));
    }
}
