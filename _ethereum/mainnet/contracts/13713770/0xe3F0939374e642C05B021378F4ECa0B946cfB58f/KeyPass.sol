// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Go to https://friendsies.io for more information.
// Built by @devloper_eth

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";

interface ProxyRegistry {
    function proxies(address) external view returns (address);
}

contract KeyPass is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    EIP712Upgradeable,
    IERC1155ReceiverUpgradeable,
    ERC1155SupplyUpgradeable,
    UUPSUpgradeable
{
    event Withdrawal(address to, uint256 value);

    event Claimed(
        bytes[] indexed key,
        address indexed minter,
        uint256 tokenId,
        uint256 amount
    );

    struct SignedTicket {
        /// @dev key is calculated like this:
        /// @dev toHash(scheme, value) { return keccak256(lowercase(scheme + "://" + value)) }
        bytes[] key;
        address minter;
        uint256 tokenId;
        uint256 expires;
        bytes signature;
    }

    mapping(bytes => mapping(uint256 => bool)) public minted; // map[key][tokenId] = bool
    mapping(uint256 => uint256) public maxSupply; // map[tokenId] = amount

    address public signer;
    ProxyRegistry public proxyRegistry;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // solhint-disable func-visibility
    // solhint-disable no-empty-blocks
    constructor() initializer {}

    function initialize(
        address _signer,
        string calldata _uri,
        ProxyRegistry _proxyRegistry
    ) public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        __EIP712_init("friendsies", "1");
        __ERC1155Supply_init();
        __ERC1155_init(_uri);
        __UUPSUpgradeable_init();
        signer = _signer;
        proxyRegistry = _proxyRegistry;
    }

    function mintableSupply(uint256 _tokenId) public view returns (uint256) {
        uint256 total = totalSupply(_tokenId);
        uint256 max = maxSupply[_tokenId];
        if (total >= max) {
            return 0;
        }
        return max - total;
    }

    function claim(SignedTicket calldata _ticket)
        external
        nonReentrant
        whenNotPaused
    {
        require(signer == _verify(_ticket), "Invalid ticket"); // hint: could be wrong signer
        require(_ticket.expires > block.number, "Ticket expired");

        for (uint256 i = 0; i < _ticket.key.length; i++) {
            require(!minted[_ticket.key[i]][_ticket.tokenId], "Already minted");
        }

        require(_ticket.minter != address(0), "Minter can't be zero address");
        require(_ticket.minter == msg.sender, "Sender is not minter");
        require(mintableSupply(_ticket.tokenId) > 0, "Out of tokens");

        for (uint256 i = 0; i < _ticket.key.length; i++) {
            minted[_ticket.key[i]][_ticket.tokenId] = true;
        }

        emit Claimed(_ticket.key, _ticket.minter, _ticket.tokenId, 1);
        _mint(_ticket.minter, _ticket.tokenId, 1, "");
    }

    function setMaxSupply(uint256 _tokenId, uint256 _max) external onlyOwner {
        maxSupply[_tokenId] = _max;
    }

    function setURI(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setProxyRegistry(ProxyRegistry _proxyRegistry) external onlyOwner {
        proxyRegistry = _proxyRegistry;
    }

    function _verify(SignedTicket calldata _ticket)
        private
        view
        returns (address)
    {
        bytes32 digest = _hashTypedData(_ticket);
        return ECDSAUpgradeable.recover(digest, _ticket.signature);
    }

    function _hashTypedData(SignedTicket calldata _ticket)
        private
        view
        returns (bytes32)
    {
        bytes memory key;
        for (uint256 i = 0; i < _ticket.key.length; i++) {
            key = bytes.concat(key, keccak256(_ticket.key[i]));
        }

        // https://eips.ethereum.org/EIPS/eip-712#definition-of-typed-structured-data-%F0%9D%95%8A
        // https://docs.openzeppelin.com/contracts/4.x/api/utils#EIP712-_hashTypedDataV4-bytes32-
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "SignedTicket(bytes[] key,address minter,uint256 tokenId,uint256 expires)"
                        ),
                        keccak256(key),
                        _ticket.minter,
                        _ticket.tokenId,
                        _ticket.expires
                    )
                )
            );
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function onERC1155Received(
        address _operator,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external view override returns (bytes4) {
        require(_operator == owner(), "Only owner");
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address _operator,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external view override returns (bytes4) {
        require(_operator == owner(), "Only owner");
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
    function isApprovedForAll(address _account, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(_account) == _operator) {
            return true;
        }

        return super.isApprovedForAll(_account, _operator);
    }

    /// @dev allow owner to transfer ETH to any address
    function withdraw(address payable _to, uint256 _value)
        external
        nonReentrant
        onlyOwner
    {
        emit Withdrawal(_to, _value);
        _transferETH(_to, _value);
    }

    /// @dev Transfer ETH and revert if unsuccessful. Only forward 30,000 gas to the callee.
    function _transferETH(address payable _to, uint256 _value) private {
        (bool success, ) = _to.call{value: _value, gas: 30_000}(new bytes(0)); // solhint-disable-line avoid-low-level-calls
        require(success, "Transfer failed");
    }

    receive() external payable {} // solhint-disable-line no-empty-blocks
}
