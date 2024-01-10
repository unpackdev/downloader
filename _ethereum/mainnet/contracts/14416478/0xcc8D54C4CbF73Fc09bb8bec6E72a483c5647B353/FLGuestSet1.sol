// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

contract FLGuestSet1 is ERC721Enumerable, ContextMixin, Ownable {
    uint public constant MAX_CAP = 200;
    string _baseTokenURI;

    address proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    bool secondHalfEnabled = false;

    uint256 public TOKEN_PRICE = 175000000000000000; //0.175 ETH

    address fees_own = 0x3D07AeD703a224910Cf9F919bD68A43594405cf5; //50%
    address fees_fl = 0x3c93ECd652aDCd2Ad86227e8fB2dE5dF0511Cb52; //40%
    address fees_dev = 0x4076899bb34B4Af5faaDF6d574be58c935faff97; //10%

    //Event to tell OpenSea that this item is frozen
    event PermanentURI(string _value, uint256 indexed _id);

    mapping(uint256=>string) public frozenUris;

    constructor() ERC721("FLGuestSet1", "FLGuestSet1")  {
        setBaseURI('https://flukenft.com/api/subset/3/token/');
    }

    function mint(uint _tokenId) public payable {
        require(_tokenId < 100 || secondHalfEnabled, "Second half not enabled");
        require(_tokenId < MAX_CAP, "Max limit");
        require(!_exists(_tokenId), "Already minted");
        require(msg.value == TOKEN_PRICE, "Invalid price");

        _safeMint(msg.sender, _tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _enableSecondHalf() public onlyOwner {
        secondHalfEnabled = true;
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
    
    function tokenURI(uint256 _input) public view virtual override returns (string memory) {
        if (bytes(frozenUris[_input]).length > 0) {
            return frozenUris[_input];
        }
        return ERC721.tokenURI(_input);
    }
    
    function freeze(string memory _value, uint256 _id) public onlyOwner {
        require(bytes(frozenUris[_id]).length == 0, "Already freezed");

        frozenUris[_id] = _value;
        emit PermanentURI(_value, _id);
    }

    function withdrawFees() public payable {
        uint balance = address(this).balance;

        uint256 dev = balance / 10;
        uint256 fl = dev * 4;
        uint256 own = balance - dev - fl; 

        require(payable(fees_dev).send(dev));
        require(payable(fees_fl).send(fl));
        require(payable(fees_own).send(own));
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
    
    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override(ERC721, IERC721) view returns (bool isOperator) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }
}