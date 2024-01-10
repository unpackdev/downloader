// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Strings.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract MetaMech is ERC721A, Ownable {
    using Address for address;
    using Strings for uint256;
    uint256 internal constant MAX_LIMIT = 6666;
    uint256 internal constant MAX_SALE_LIMIT = 6466;
    uint256 internal constant PRE_SALE_ONCE_LIMIT = 2;
    uint256 internal constant NORMAL_SALE_ONCE_LIMIT = 5;

    uint256 public preSalePrice;
    uint256 public normalPrice;
    string public baseURI;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    mapping(address => bool) private whiteList;
    mapping(address => bool) private whiteListMinted;
    address private foundAddr;
    address proxyRegistryAddress;
    bool private reveal;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721A(_name, _symbol) {
        preSalePrice = 0.04 ether;
        normalPrice = 0.06 ether;
        proxyRegistryAddress = _proxyRegistryAddress;
        //TODO: change founder address later?
        foundAddr = address(0x221ce8b7a5856ED901a65ff5DdA28cDB2F1B2E57);
        baseURI = "https://knightlab.mypinata.cloud/ipfs/QmeCx4Q6MVDdxr9iJjF1WWiFqocD3NBe6esmbnHQFKrxoy/Meta_Mech_final_reveal_metadata.json";
    }

    function setPreSalePrice(uint256 _preSalePrice) public onlyOwner {
        preSalePrice = _preSalePrice;
    }

    function setNormalPrice(uint256 _normalPrice) public onlyOwner {
        normalPrice = _normalPrice;
    }

    function setFoundAddr(address _foundAddr) public onlyOwner {
        require(_foundAddr != address(0), "zero address");
        foundAddr = _foundAddr;
    }

    function setPreSaleTime(uint256 _preSaleStartTime, uint256 _preSaleEndTime)
        public
        onlyOwner
    {
        require(_preSaleStartTime < _preSaleEndTime, "invalid args");
        require(block.timestamp < _preSaleEndTime, "end time invalid");
        require(0 < _preSaleStartTime, "start time invalid");
        preSaleStartTime = _preSaleStartTime;
        preSaleEndTime = _preSaleEndTime;
    }

    function addWhiteList(address[] calldata users) public onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            whiteList[users[i]] = true;
        }
    }

    function removeWhiteList(address[] calldata users) public onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            whiteList[users[i]] = false;
            whiteListMinted[users[i]] = false;
        }
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _tos address of the future owner of the token
     */
    function mintTo(address[] calldata _tos, uint256 _amount) public onlyOwner {
        uint256 _mintedAmt = _totalMinted();
        uint256 _mintAmt = _tos.length * _amount;
        require(
            _mintedAmt + _mintAmt <= MAX_LIMIT,
            "MetaMech: reached max limit"
        );
        for (uint256 i = 0; i < _tos.length; i++) {
            address _to = _tos[i];
            _mint(_to, _amount, "", false);
        }
    }

    function presale(uint256 num) public payable {
        require(
            _totalMinted() + num <= MAX_SALE_LIMIT,
            "MetaMech: reached max limit at presale"
        );
        require(
            preSaleStartTime <= block.timestamp &&
                block.timestamp < preSaleEndTime,
            "MetaMech: presale not started"
        );
        require(whiteList[_msgSender()], "MetaMech: invalid whitelist user.");
        require(
            !whiteListMinted[_msgSender()],
            "MetaMech: whitelist user has already minted"
        );
        require(
            num <= PRE_SALE_ONCE_LIMIT,
            "MetaMech: over maximum of NFT allowed per whitelist user"
        );
        require(
            msg.value >= num * preSalePrice,
            "MetaMech: presale price error, please check msg.value."
        );
        _mint(_msgSender(), num, "", false);
        whiteListMinted[_msgSender()] = true;
        if (foundAddr != address(0)) {
            payable(foundAddr).transfer(msg.value);
        }
    }

    function mint(uint256 num) public payable {
        require(
            _totalMinted() + num <= MAX_SALE_LIMIT,
            "MetaMech: reached max limit at public sale"
        );

        require(
            preSaleEndTime > 0 && block.timestamp >= preSaleEndTime,
            "MetaMech: public sale not started"
        );

        require(
            num <= NORMAL_SALE_ONCE_LIMIT,
            "MetaMech: over maximum of NFT allowed per user"
        );
        require(
            msg.value >= num * normalPrice,
            "MetaMech: price error, please check price."
        );
        _mint(_msgSender(), num, "", false);

        if (foundAddr != address(0)) {
            payable(foundAddr).transfer(msg.value);
        }
    }

    function setBaseURI(string calldata _baseURI_) public onlyOwner {
        baseURI = _baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return ERC721A.isApprovedForAll(owner, operator);
    }

    function setReveal(bool _reveal) public onlyOwner {
        reveal = _reveal;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (reveal) {
            return
                bytes(baseURI).length > 0
                    ? string(
                        abi.encodePacked(baseURI, tokenId.toString(), ".json")
                    )
                    : "";
        } else {
            return bytes(baseURI).length > 0 ? baseURI : "";
        }
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    /** Token starts from token 1 */

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
