// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./AgentDsSecretRoom.sol";
import "./DuckOwnerProxy.sol";

contract SecretAgentAcademy is FactoryERC721, Ownable {
    using SafeMath for uint256;

    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    mapping(uint16 => bool) public mintsFromDuckIDs;

    mapping(address => bool) public presaleWhitelist;

    address public proxyRegistryAddress;
    address public nftAddress;
    address public duckOwnerProxyAdress;
    string public baseURI;

    uint256 public presaleTime = 0;
    uint256 public presaleEndTime = 0;

    uint256 MAX_SUPPLY = 10000;

    uint256 NUM_OPTIONS = 3;
    uint256 SINGLE_OPTION = 0;
    uint256 MULTIPLE_OPTION_5 = 1;
    uint256 MULTIPLE_OPTION_10 = 2;

    modifier onlyPresaleWhitelisted() {
        require(
            presaleWhitelist[msg.sender],
            "You're not whitelisted for pre-sale."
        );
        _;
    }

    // left goto1 

    constructor(address _proxyRegistryAddress, address _nftAddress, address _duckOwnerProxyAdress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;
        duckOwnerProxyAdress = _duckOwnerProxyAdress;

        fireTransferEvents(address(0), owner());
    }

    function name() override external pure returns (string memory) {
        return "Secret Agent Academy";
    }

    function symbol() override external pure returns (string memory) {
        return "SAA";
    }

    function supportsFactoryInterface() override public pure returns (bool) {
        return true;
    }

    function numOptions() override public view returns (uint256) {
        return NUM_OPTIONS;
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < NUM_OPTIONS; i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function setPresaleTimes(
        uint256 _presaleTime,
        uint256 _presaleEndTime
    ) external onlyOwner {
        presaleTime = _presaleTime;
        presaleEndTime = _presaleEndTime;
    }

    function presale(uint256 _amount) external payable onlyPresaleWhitelisted {
        require(
            block.timestamp >= presaleTime && block.timestamp < presaleEndTime,
            "No presale going on at the moment."
        );
        AgentDsSecretRoom nft = AgentDsSecretRoom(nftAddress);
        address toAddress = _msgSender();
        require(
            (_amount + nft.balanceOf(toAddress)) <= 5,
            "Up to 5 NFTs can be purchased in the presale."
        );
        require(
            msg.value == uint256(_amount) * 0.045 ether,
            "You need to pay the exact price."
        );
        uint256 totalSupply = nft.totalSupply();
        require(totalSupply <= (MAX_SUPPLY - _amount), "Not enough NFTs in stock");
        for (
            uint256 i = 0;
            i < _amount;
            i++
        ) {
            nft.mintTo(toAddress);
        }
    }

    function mintFromDuck(uint16 _duckID) external {
        require(!mintsFromDuckIDs[_duckID], "Already minted from this duck");
        DuckOwnerProxy duckOwnerProxy = DuckOwnerProxy(duckOwnerProxyAdress);
        require(duckOwnerProxy.checkIfDuckOwner(_duckID), "You should own this duck in order to use it.");
        AgentDsSecretRoom nft = AgentDsSecretRoom(nftAddress);
        address toAddress = _msgSender();
        uint256 totalSupply = nft.totalSupply();
        require(totalSupply <= (MAX_SUPPLY - 1), "Not enough NFTs in stock");
        nft.mintTo(toAddress);
        mintsFromDuckIDs[_duckID] = true;
    }

    function mint(uint256 _optionId, address _toAddress) override public {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            address(proxyRegistry.proxies(owner())) == _msgSender() ||
                owner() == _msgSender()
        );
        require(canMint(_optionId));

        AgentDsSecretRoom nft = AgentDsSecretRoom(nftAddress);
        uint256 numberToMint = 0;
        if (_optionId == SINGLE_OPTION) {
            numberToMint = 1;
        } else if (_optionId == MULTIPLE_OPTION_5) {
            numberToMint = 5;
        } else if (_optionId == MULTIPLE_OPTION_10) {
            numberToMint = 10;
        }

        require(_toAddress == owner() || (nft.balanceOf(_toAddress) + numberToMint) <= 15, "Only up to 15 NFT per owner" );

        for (
            uint256 i = 0;
            i < numberToMint;
            i++
        ) {
            nft.mintTo(_toAddress);
        }
   } 

    function canMint(uint256 _optionId) override public view returns (bool) {
        if (_optionId >= NUM_OPTIONS) {
            return false;
        }

        AgentDsSecretRoom nft = AgentDsSecretRoom(nftAddress);
        uint256 totalSupply = nft.totalSupply();

        uint256 numItemsAllocated = 0;
        if (_optionId == SINGLE_OPTION) {
            numItemsAllocated = 1;
        } else if (_optionId == MULTIPLE_OPTION_5) {
            numItemsAllocated = 5;
        } else if (_optionId == MULTIPLE_OPTION_10) {
            numItemsAllocated = 10;
        }
        return totalSupply <= (MAX_SUPPLY - numItemsAllocated);
    }

    function tokenURI(uint256 _optionId) override external view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_optionId)));
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(
        address /* _from */,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }
        return false;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "You just wasted gas on trying to withdraw nada...");
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256 /*_tokenId*/) public view returns (address _owner) {
        return owner();
    }

    function setBaseUri(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function addAddressesToPresaleWhitelist(address[] memory addrs) public onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            presaleWhitelist[addrs[i]] = true;
        }
    }
    // We got taken!
}
