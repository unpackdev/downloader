//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC2981PerTokenRoyalties.sol";




contract RareAlley is ERC721URIStorage, ERC2981PerTokenRoyalties, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

	event NftBought(address _seller, address _buyer, uint256 _price);
	event Transfer_do(address indexed _from, address indexed _to, uint256 indexed _tokenId);
	event royaltyinfodata(address indexed _from, uint256 royaltyAmount);
	event royaltyinfodata2(address indexed _from, address royaltyreceiver);
	event performbasetransaction_do(address indexed exchange, address indexed _from);
	
	mapping (uint256 => uint256) public tokenIdToPrice;
	 mapping(uint256 => address) internal idToOwner;

	string public _name;
	string public _symbol;
	string public contractname;
	string public contractsymbol;
	uint256 nextTokenId;

	 constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}
	
	
	    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

	string private statename = "OPS";
	
	 function getContractState() public view returns (string memory)
    {
        return statename;
    }

    function setContractState(string memory newState) public onlyOwner
    {
        statename = newState;
    }
	
	 function getprice(uint256 _tokenId) public view returns (uint256)
    {
		uint256 price = tokenIdToPrice[_tokenId];
        return price;
    }
	
	
    function mintNFT(address recipient, string memory tokenURI)
       // public onlyOwner
        public returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
	
	  function PurchaseWithMint(address recipient, string memory tokenURI, address seller, address exchange, address royaltyRecipient, uint256 royaltyValue, uint256 issafe, uint256 comm) external payable
       // public onlyOwner
       returns (uint256) 
    {
   
		uint256 commission = (msg.value * comm) / 10000;

		uint256 paymenttoseller = msg.value - commission;
		
		payable(seller).transfer(paymenttoseller); // send the ETH to the seller
		payable(exchange).transfer(commission); //send commission to exchange

		
		_tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
		
		if (issafe == 1){
			_safeMint(recipient, newItemId, '');
		}else {
			_mint(recipient, newItemId);	
		}
        _setTokenURI(newItemId, tokenURI);
		
		if (royaltyValue > 0) {
            _setTokenRoyalty(newItemId, royaltyRecipient, royaltyValue);
        }
		
        return newItemId;
    }
	

    function mintBatch(address exchange,
		string[] memory tokenURIs,
		address[] memory sellers,
        address[] memory recipients,
        address[] memory royaltyRecipients,
        uint256[] memory royaltyValues, uint256 issafe, uint256 comm
    ) external payable {
			uint256 tokenId = nextTokenId;
			require(
				recipients.length == royaltyRecipients.length &&
					recipients.length == royaltyValues.length,
				'ERC721: Arrays length mismatch'
			);

			for (uint256 i; i < recipients.length; i++) {
				
				uint256 commission = (msg.value * comm) / 10000;
				
				uint256 paymenttoseller = msg.value - commission;

				payable(sellers[i]).transfer(paymenttoseller); // send the ETH to the seller
				payable(exchange).transfer(commission); //send commission to exchange
				if (issafe == 1){
					_safeMint(recipients[i], tokenId, '');
				}else {
					_mint(recipients[i], tokenId);	
				}
				_setTokenURI(tokenId, tokenURIs[i]);
				if (royaltyValues[i] > 0) {
					_setTokenRoyalty(
						tokenId,
						royaltyRecipients[i],
						royaltyValues[i]
					);
				}
				tokenId++;
			}

			nextTokenId = tokenId;
		}
	

	
	    function transferBatch(address exchange,
		uint256[] memory tokenIds,
		address[] memory sellers,
        address[] memory recipients,
        address[] memory royaltyRecipients,
        uint256[] memory royaltyValues, uint256 issafe, uint256 comm
    ) external payable onlyOwner {
			uint256 tokenId = nextTokenId;
			require(
				recipients.length == royaltyRecipients.length &&
					recipients.length == royaltyValues.length,
				'ERC721: Arrays length mismatch'
			);

			for (uint256 i; i < recipients.length; i++) {
				
				uint256 commission = (msg.value * comm) / 10000;

				address royaltyRecipient;
				uint256 royaltyAmount;
				RoyaltyInfo memory royalties = _royalties[tokenIds[i]];
				royaltyRecipient = royalties.recipient;
				royaltyAmount = (msg.value * royalties.amount) / 10000;
 
				uint256 paymenttoseller = msg.value - (commission + royaltyAmount);

				payable(sellers[i]).transfer(paymenttoseller); // send the ETH to the seller
				payable(exchange).transfer(commission); //send commission to exchange

				payable(royaltyRecipient).transfer(royaltyAmount); //send royalty to royalty receipient
				
				dotransferbatch(tokenIds[i],sellers[i], recipients[i], issafe);
		
			
		
			
			}

		
		}
	
	  function dotransferbatch(uint256 tokenIds, address sellers, address recipients, uint256 issafe) public{
		  
		  	if (issafe == 1){
					safeTransferFrom(sellers,recipients,tokenIds, '');
				}else {
					transferFrom(sellers,recipients,tokenIds);
				}
				emit Transfer_do(recipients, sellers, tokenIds);
				
	  }
	  
	  function PurchaseWithInternalTransfer(address recipient, uint256 _tokenId, address seller, address exchange, uint256 issafe, uint256 comm) external payable onlyOwner
    {
   
		uint256 commission = (msg.value * comm) / 10000;
		
		address royaltyRecipient;
		uint256 royaltyAmount;
		RoyaltyInfo memory royalties = _royalties[_tokenId];
        royaltyRecipient = royalties.recipient;
        royaltyAmount = (msg.value * royalties.amount) / 10000;	
		
		//remainder goes to seller 
		uint256 paymenttoseller = msg.value - (commission + royaltyAmount);
		payable(seller).transfer(paymenttoseller); // send the ETH to the seller
		payable(exchange).transfer(commission); //send commission to exchange
		

		payable(royaltyRecipient).transfer(royaltyAmount); //send royalty to royalty receipient
		
		if (issafe == 1){
			safeTransferFrom(seller,recipient,_tokenId, '');
		}else {
			transferFrom(seller,recipient,_tokenId);
		}
		emit Transfer_do(recipient, seller, _tokenId);
	
    }
	
	function performbasetransaction(address exchange) external payable
	{
		
		payable(exchange).transfer(msg.value);
		emit performbasetransaction_do(exchange, msg.sender);
		
	}
	
	function showroyaltydata(uint256 _tokenId, uint256 payingin, uint256 needamount) external {
		address royaltyRecipient;
		uint256 royaltyAmount;

		RoyaltyInfo memory royalties = _royalties[_tokenId];
        royaltyRecipient = royalties.recipient;
        royaltyAmount = (payingin * royalties.amount) / 10000;
		
		//(royaltyRecipient, royaltyAmount) = royaltyInfo(_tokenId, payingin);
		if (needamount == 1){
		 emit royaltyinfodata(msg.sender, royaltyAmount);
		}else {
		 emit royaltyinfodata2(msg.sender, royaltyRecipient);	
		}
	}
	

	 function showroyaltydatareturnsamount(uint256 _tokenId, uint256 payingin, uint256 needamount) public view returns (uint256)
    {
		
			address royaltyRecipient;
		uint256 royaltyAmount;

		RoyaltyInfo memory royalties = _royalties[_tokenId];
        royaltyRecipient = royalties.recipient;
        royaltyAmount = (payingin * royalties.amount) / 10000;
		
        return royaltyAmount;
    }
	
	
		function showroyaltydatareturnsreceipient(uint256 _tokenId, uint256 payingin, uint256 needamount) public view returns (address)
    {
		
			address royaltyRecipient;
		uint256 royaltyAmount;

		RoyaltyInfo memory royalties = _royalties[_tokenId];
        royaltyRecipient = royalties.recipient;
        royaltyAmount = (payingin * royalties.amount) / 10000;
		
        return royaltyRecipient;
    }
	
	
	function transfer_do(address _to, uint256 _tokenId) public {
     require(msg.sender == idToOwner[_tokenId]);
     idToOwner[_tokenId] = _to;
     emit Transfer_do(msg.sender, _to, _tokenId);
	}
	
}