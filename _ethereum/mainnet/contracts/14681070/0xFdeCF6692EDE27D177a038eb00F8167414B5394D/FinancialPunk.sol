// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IPunk.sol";

contract UserProxy {
    address private _owner;

    /**
     * @dev Initializes the contract settings
     */
    constructor() public {
        _owner = msg.sender;
    }

    /**
     * @dev Transfers punk to the smart contract owner
     */
    function transfer(address punkContract, uint256 punkIndex)
        external
        returns (bool)
    {
        if (_owner != msg.sender) {
            return false;
        }

        (bool result, ) = punkContract.call(
            abi.encodeWithSignature(
                "transferPunk(address,uint256)",
                _owner,
                punkIndex
            )
        );

        return result;
    }
}

contract FinancialPunk is Ownable, ERC721 {
    event ProxyRegistered(address user, address proxy);

    // Instance of cryptopunk smart contracts
    IPunkMarket public _punkContract;
    IPunkData public _punkData;

    // Mapping from user address to proxy address
    mapping(address => address) public _proxies;

    /**
     * @dev Initializes the contract settings
     */
    constructor(address punkContract, address punkData)
        public
        ERC721("Financial Cryptopunks", "fiPUNKS")
    {
        _punkContract = IPunkMarket(punkContract);
        _punkData = IPunkData(punkData);
    }

    /**
     * @dev Registers proxy
     */
    function registerProxy() public {
        address sender = _msgSender();

        require(
            _proxies[sender] == address(0),
            "FinancialPunk: caller has registered the proxy"
        );

        address proxy = address(new UserProxy());

        _proxies[sender] = proxy;

        emit ProxyRegistered(sender, proxy);
    }

    /**
     * @dev Mints a financial punk
     */
    function mint(uint256 punkIndex) public {
        address sender = _msgSender();

        UserProxy proxy = UserProxy(_proxies[sender]);

        require(
            proxy.transfer(address(_punkContract), punkIndex),
            "FinancialPunk: transfer fail"
        );

        _mint(sender, punkIndex);
    }

    /**
     * @dev Burns a specific financial punk
     */
    function burn(uint256 punkIndex) public {
        address sender = _msgSender();

        require(
            _isApprovedOrOwner(sender, punkIndex),
            "FinancialPunk: caller is not owner nor approved"
        );

        _burn(punkIndex);

        // Transfers ownership of punk on original cryptopunk smart contract to caller
        _punkContract.transferPunk(sender, punkIndex);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        address sender = _msgSender();
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        if (_exists(tokenId)) {
            _transfer(from, to, tokenId);
        } else {
            UserProxy proxy = UserProxy(_proxies[from]);

            require(
                proxy.transfer(address(_punkContract), tokenId),
                "FinancialPunk: transfer fail"
            );

            _mint(to, tokenId);
        }
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (operator == owner()) {
            return true;
        } else {
            return ERC721.isApprovedForAll(account, operator);
        }
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        if (spender == owner()) {
            return true;
        } else {
            return ERC721._isApprovedOrOwner(spender, tokenId);
        }
    }

    function punkImageSvg(uint16 index)
        external
        view
        returns (string memory svg)
    {
        return _punkData.punkImageSvg(index);
    }
}
