// SPDX-License-Identifier: MIT
// ENVELOP protocol for NFT. Mintable User NFT Collection
pragma solidity 0.8.16;

import "ERC1155URIStorage.sol";
import "Ownable.sol";
import "ECDSA.sol";
import "Subscriber.sol";


contract EnvelopUsers1155Swarm is ERC1155URIStorage, Ownable, Subscriber {
    using ECDSA for bytes32;

    
    string public  name;
    string public  symbol;
    //address public subscriptionManager;
    //string private _baseTokenURI;

    
    // Oracle signers status
    mapping(address => bool) public oracleSigners;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _baseurl,
        uint256 _code
    ) 
        ERC1155(string(abi.encodePacked(_baseurl, "{id}")))
        Subscriber(_code)  
    {
        name = name_;
        symbol = symbol_;
        _setBaseURI(_baseurl);

    }

    ///////////////////////////////////////////////////////////////////////////
    ////  Section below is OppenZeppelin ERC1155Supply inmplementation     ////
    ///////////////////////////////////////////////////////////////////////////
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }

    ///////////////////////////////////////////////////////////////////////////

    function mintWithURI(
        address _to, 
        uint256 _tokenId, 
        uint256 _amount,
        string calldata _tokenURI, 
        bytes calldata _signature
    ) public {
        // If signature present - lets checkit
        if (_signature.length > 0) {
            bytes32 msgMustWasSigned = keccak256(abi.encode(
                msg.sender,
                _tokenId,
                _tokenURI,
                _amount
            )).toEthSignedMessageHash();

            // Check signature  author
            require(oracleSigners[msgMustWasSigned.recover(_signature)], "Unexpected signer");

        // If there is no signature then sender must have valid status
        } else {
            require(
                _checkAndFixSubscription(msg.sender),
                "Has No Subscription"
            );

        }
        _mintWithURI(_to, _tokenId, _amount, _tokenURI);
    }

    function mintWithURIBatch(
        address[] calldata _to, 
        uint256[] calldata _tokenId,
        uint256[] calldata _amounts, 
        string[] calldata _tokenURI, 
        bytes[] calldata _signature
    ) external {
        for (uint256 i = 0; i < _to.length; i ++){
            mintWithURI(_to[i], _tokenId[i], _amounts[i], _tokenURI[i], _signature[i]);
        }
    }

    //////////////////////////////
    //  Admin functions        ///
    //////////////////////////////
    function setSignerStatus(address _signer, bool _status) external onlyOwner {
        oracleSigners[_signer] = _status;
    }

    function setSubscriptionManager(address _manager) external onlyOwner {
        _setSubscriptionManager(_manager);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _setBaseURI(_newBaseURI);
    }
    ///////////////////////////////

    function _mintWithURI(
        address _to, 
        uint256 _tokenId, 
        uint256 _amount, 
        string memory _tokenURI
    ) internal {
        require(!exists(_tokenId),"This id already minted");
        _mint(_to, _tokenId, _amount, "");
        _setURI(_tokenId, _tokenURI);
    }

}