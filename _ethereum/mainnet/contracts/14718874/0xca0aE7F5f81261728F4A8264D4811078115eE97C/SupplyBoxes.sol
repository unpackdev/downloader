// SPDX-License-Identifier: MIT

/**
    IMPORTANT NOTICE:
    This smart contract was written and deployed by the software engineers at 
    https://highstack.co in a contractor capacity.
    
    Highstack is not responsible for any malicious use or losses arising from using 
    or interacting with this smart contract.

    THIS CONTRACT IS PROVIDED ON AN “AS IS” BASIS. USE THIS SOFTWARE AT YOUR OWN RISK.
    THERE IS NO WARRANTY, EXPRESSED OR IMPLIED, THAT DESCRIBED FUNCTIONALITY WILL 
    FUNCTION AS EXPECTED OR INTENDED. PRODUCT MAY CEASE TO EXIST. NOT AN INVESTMENT, 
    SECURITY OR A SWAP. TOKENS HAVE NO RIGHTS, USES, PURPOSE, ATTRIBUTES, 
    FUNCTIONALITIES OR FEATURES, EXPRESS OR IMPLIED, INCLUDING, WITHOUT LIMITATION, ANY
    USES, PURPOSE OR ATTRIBUTES. TOKENS MAY HAVE NO VALUE. PRODUCT MAY CONTAIN BUGS AND
    SERIOUS BREACHES IN THE SECURITY THAT MAY RESULT IN LOSS OF YOUR ASSETS OR THEIR 
    IMPLIED VALUE. ALL THE CRYPTOCURRENCY TRANSFERRED TO THIS SMART CONTRACT MAY BE LOST.
    THE CONTRACT DEVLOPERS ARE NOT RESPONSIBLE FOR ANY MONETARY LOSS, PROFIT LOSS OR ANY
    OTHER LOSSES DUE TO USE OF DESCRIBED PRODUCT. CHANGES COULD BE MADE BEFORE AND AFTER
    THE RELEASE OF THE PRODUCT. NO PRIOR NOTICE MAY BE GIVEN. ALL TRANSACTION ON THE 
    BLOCKCHAIN ARE FINAL, NO REFUND, COMPENSATION OR REIMBURSEMENT POSSIBLE. YOU MAY 
    LOOSE ALL THE CRYPTOCURRENCY USED TO INTERACT WITH THIS CONTRACT. IT IS YOUR 
    RESPONSIBILITY TO REVIEW THE PROJECT, TEAM, TERMS & CONDITIONS BEFORE USING THE 
    PRODUCT.

**/

pragma solidity ^0.8.4;

import "./ERC1155Supply.sol";
import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";
import "./ControlledAccess.sol";

contract SupplyBoxes is
    ERC1155Supply,
    Ownable,
    ReentrancyGuard,
    ControlledAccess
{
    using ECDSA for bytes32;
    using SafeMath for uint256;

    string public name = "Warrior Alliance Supply Boxes";
    string public baseUri = "";

    // Mapping of TokenID to the max supply of each token.
    mapping(uint256 => uint256) public maxSupply; // default zero
    mapping(uint256 => bool) public isPublicLive; // default false
    mapping(uint256 => bool) public isWhitelistLive; // default false
    mapping(uint256 => uint256) public price; // default zero
    mapping(uint256 => uint256) public maxMint; // default zero
    mapping(uint256 => uint256) public startTime; // default zero

    // Keep track of addresses that have claimed whitelist mints.
    /** 
      privateMintClaimed = {
        [currentWhitelistNonce] : {
          [tokenId] : {
            [address] : boolean
          }
        }
      }
    **/
    mapping(uint256 => mapping(uint256 => mapping(address => bool)))
        public privateMintClaimed;

    constructor() ERC1155("") {
        maxSupply[1] = 480; // cargo box (first drop)
        maxSupply[2] = 20; // mystery box (first drop)
    }

    /***********************/
    /***********************/
    /***********************/
    /*** ADMIN FUNCTIONS ***/
    /***********************/
    /***********************/
    /***********************/
    /***********************/

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function setName(string memory _name) public onlyOwner {
        name = _name;
    }

    function setMaxSupply(uint256 _tokenId, uint256 _maxSupply)
        public
        onlyOwner
    {
        require(
            totalSupply(_tokenId) <= _maxSupply,
            "Cannot set max supply less than existing supply"
        );
        maxSupply[_tokenId] = _maxSupply;
    }

    function setIsLive(
        uint256 _tokenId,
        bool _isPublicLive,
        bool _isWhitelistLive
    ) public onlyOwner {
        isPublicLive[_tokenId] = _isPublicLive;
        isWhitelistLive[_tokenId] = _isWhitelistLive;
    }

    function setMaxMint(uint256 _tokenId, uint256 _maxMint) public onlyOwner {
        maxMint[_tokenId] = _maxMint;
    }

    function setStartTime(uint256 _tokenId, uint256 _startTime)
        public
        onlyOwner
    {
        startTime[_tokenId] = _startTime;
    }

    function setPrice(uint256 _tokenId, uint256 _price) public onlyOwner {
        price[_tokenId] = _price;
    }

    function withdraw(address _address, uint256 _amount) public onlyOwner {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function adminMint(
        address _address,
        uint256 _tokenId,
        uint256 _amount
    ) public onlyOwner {
        require(
            totalSupply(_tokenId).add(_amount) <= maxSupply[_tokenId],
            "Max supply exceeded"
        );
        _mint(_address, _tokenId, _amount, "");
    }

    /************************/
    /************************/
    /************************/
    /*** PUBLIC FUNCTIONS ***/
    /************************/
    /************************/
    /************************/
    /************************/

    function whitelistMint(
        uint256 tokenId,
        uint256 amount,
        uint256 whitelistNonce,
        bytes32 msgHash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public payable nonReentrant {
        require(msg.value >= calcPrice(tokenId, amount), "Value below price");
        require(isWhitelistLive[tokenId], "Whitelist not open");
        require(block.timestamp > startTime[tokenId], "Start time not reached");
        require(
            totalSupply(tokenId).add(amount) <= maxSupply[tokenId],
            "Max supply exceeded"
        );

        // Security check.
        bytes32 calculatedMsgHash = keccak256(
            abi.encodePacked(msg.sender, tokenId, amount, whitelistNonce)
        );

        address signer = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash)
            ),
            _v,
            _r,
            _s
        );
        require(calculatedMsgHash == msgHash, "Invalid hash");
        require(owner() == signer, "Access denied");
        require(
            !privateMintClaimed[whitelistNonce][tokenId][msg.sender],
            "Already claimed!"
        );

        // Let's mint!
        privateMintClaimed[whitelistNonce][tokenId][msg.sender] = true;
        _mint(msg.sender, tokenId, amount, "");
    }

    function mint(uint256 tokenId, uint256 amount) public payable nonReentrant {
        require(msg.value >= calcPrice(tokenId, amount), "Value below price");
        require(isPublicLive[tokenId], "Public sale not open");
        require(block.timestamp > startTime[tokenId], "Start time not reached");
        require(
            totalSupply(tokenId).add(amount) <= maxSupply[tokenId],
            "Max supply exceeded"
        );
        require(amount <= maxMint[tokenId], "Max limit per mint");
        _mint(msg.sender, tokenId, amount, "");
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseUri, Strings.toString(_tokenId), ".json")
            );
    }

    /** HELPER FUNCTIONS **/
    function calcPrice(uint256 _tokenId, uint256 _count)
        public
        view
        returns (uint256)
    {
        return price[_tokenId].mul(_count);
    }
}
