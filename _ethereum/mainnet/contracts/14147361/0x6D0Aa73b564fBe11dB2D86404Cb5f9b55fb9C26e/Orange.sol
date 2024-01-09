// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721EnumerableAlt.sol";
import "./Strings.sol";

contract Orange is ERC721EnumerableAlt, Ownable {

    using Strings for uint256;

	uint public constant maxWhitelistMint = 5;
    //TODO: change this
	uint public constant price = 0.02 ether;

    bytes32 root;

    bool public isPublicMint;

    uint public maxSupply = 10000;

    mapping(address => uint) numWhitelistMinted;

    string baseURI = "ipfs://QmaatGfUx4pYxnBvU1TS4W8HaBWuhT7Yyw9ZLxefXQX2oa/";

    struct RevealStruct {
        string uri;
        uint tokenRange;
    }

    RevealStruct[] public revealList;

    struct PaymentStruct {
        address membersAddress;
        uint owed;
        uint payed;
    }

    PaymentStruct[] payments;

    constructor(PaymentStruct[] memory _payments) ERC721Alt("Orange Friends", "ORANGE FRENS") {

        for(uint i = 0; i < _payments.length; i++) {
            payments.push(_payments[i]);
            _safeMint(_payments[i].membersAddress, totalSupply());
        }

    }

    function publicMint(uint _numToMint) external payable {

    	require(_numToMint > 0, "Enter a valid amount to mint");

    	uint tokenId = totalSupply();

    	address sender = _msgSender();

    	require(isPublicMint == true, "Minting isn't public");

    	require(tokenId + _numToMint < maxSupply, "Max supply has been reached");

    	require(price * _numToMint == msg.value, "Invalid value sent to mint");

    	for(uint i = 0; i < _numToMint; i++) {

    		_safeMint(sender, tokenId + i);

    	}

    }

    function whitelistMint(uint _numToMint, bytes32[] calldata _proof) external payable {

        require(_numToMint > 0, "Enter a valid amount to mint");

        uint tokenId = totalSupply();

        address sender = _msgSender();

        require(numWhitelistMinted[sender] + _numToMint <= maxWhitelistMint, "Attempting to mint more than allowed");

        require(tokenId + _numToMint < maxSupply, "Max supply has been reached");

        require(price * _numToMint == msg.value, "Invalid value sent to mint");

        bytes32 leaf = keccak256(abi.encodePacked(sender));

        require(MerkleProof.verify(_proof, root, leaf), "Invalid proof");

        numWhitelistMinted[sender] += _numToMint;

        for(uint i = 0; i < _numToMint; i++) {

            _safeMint(sender, tokenId + i);

        }

       
    }

    function getTokensOfAddress(address _addr) public view returns(uint[] memory) {

        uint[] memory tempArray;

        uint totalSupply = totalSupply();

        tempArray = new uint[](totalSupply);
        uint total;

        for(uint i = 0; i < totalSupply; i++) {
            if(_owners[i] == _addr) {
                tempArray[total] = i;
                total++;
            }
        }

        uint[] memory finalArray = new uint[](total);
        for(uint i = 0; i < total; i++) {
            finalArray[i] = tempArray[i];
        }
        
        return finalArray;

    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {

        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory uri;

        for(uint i = 0; i < revealList.length; i++) {

            if(tokenId <= revealList[i].tokenRange) {

                uri = revealList[i].uri;
                break;

            }

        }

        if(bytes(uri).length == 0) {
            uri = baseURI;
        }

        return string(abi.encodePacked(uri, tokenId.toString()));

    }

    function getRevealStruct(uint _index) public view returns(RevealStruct memory) {
        require(_index < revealList.length, "index out of range");
        return revealList[_index];
    }
    
    function revealTokens(string memory _uri, uint _tokenRange, uint _index) external onlyOwner {

        require(_tokenRange <= maxSupply, "Cant reveal more than max supply");

        if(_index == revealList.length) {

            if(_index > 0) {
                require(_tokenRange > revealList[_index - 1].tokenRange, "TokenRange needs to be higher");
            }

            revealList.push(RevealStruct(
                _uri,
                _tokenRange
            ));

        } else {

            require(_index < revealList.length, "_index out of range");
            revealList[_index].uri = _uri;
        }
        

    }

    function togglePublicMint() external onlyOwner {

    	isPublicMint = !isPublicMint;

    }

    function setRoot(bytes32 _root) external onlyOwner {

    	root = _root;

    }

    function setBaseUri(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function withdraw() external onlyOwner {

        address thisAddress = address(this);

        require(thisAddress.balance > 0, "there is no balance in the address");
        require(payments.length > 0, "havent set the payments");

        for(uint i = 0; i < payments.length; i++) {

            if(thisAddress.balance == 0) {
                return;
            }

            PaymentStruct memory payment = payments[i];

            uint paymentLeft = payment.owed - payment.payed;

            if(paymentLeft > 0) {

                uint amountToPay;

                if(thisAddress.balance >= paymentLeft) {

                    amountToPay = paymentLeft;

                } else {
                    amountToPay = thisAddress.balance;
                }

                payment.payed += amountToPay;
                payments[i].payed = payment.payed;

                payable(payment.membersAddress).transfer(amountToPay);

            } 

        }

        if(thisAddress.balance > 0) {

            payable(payments[payments.length - 1].membersAddress).transfer(thisAddress.balance);
        }
        
    }
 
    function lowerMaxSupply(uint _newMaxSupply) external onlyOwner {
        require(_newMaxSupply >= totalSupply());
        require(_newMaxSupply < maxSupply);

        maxSupply = _newMaxSupply;
    }

}