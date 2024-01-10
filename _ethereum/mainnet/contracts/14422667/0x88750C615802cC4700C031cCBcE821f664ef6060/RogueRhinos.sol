//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

// 
// ██████╗  ██████╗  ██████╗ ██╗   ██╗███████╗   
// ██╔══██╗██╔═══██╗██╔════╝ ██║   ██║██╔════╝   
// ██████╔╝██║   ██║██║  ███╗██║   ██║█████╗     
// ██╔══██╗██║   ██║██║   ██║██║   ██║██╔══╝     
// ██║  ██║╚██████╔╝╚██████╔╝╚██████╔╝███████╗   
// ╚═╝  ╚═╝ ╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝   
//                                               
// ██████╗ ██╗  ██╗██╗███╗   ██╗ ██████╗ ███████╗
// ██╔══██╗██║  ██║██║████╗  ██║██╔═══██╗██╔════╝
// ██████╔╝███████║██║██╔██╗ ██║██║   ██║███████╗
// ██╔══██╗██╔══██║██║██║╚██╗██║██║   ██║╚════██║
// ██║  ██║██║  ██║██║██║ ╚████║╚██████╔╝███████║
// ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝
//                                              

contract RogueRhinos is ERC721, Ownable {
	uint256 private constant MAX_RHINOS = 5556; 	//5555+1 for efficient maths
	uint256 private constant MINT_MAX = 21; 		//20+1 for efficient maths
	uint256 private reserveRhinos = 101; 			//100+1, airdrops, team, promos
	uint256 public mintPrice = 0.05 ether; 
	uint256 public totalSupply;						//mimic enumerable totalSupply()
	string private baseURI; 						//metadata root
	address[6] private teamAddrs;
	mapping (address => uint256) private teamShares;
	mapping (address => uint256) public minted; 	//allowlist tracking
	address public deityAddress = address(0); 		//trusted contract with burning rights for future utility
	address private msgSigner; 						//for allowlist verification
	bool public saleLive = false;					//sale toggle
	bool public presaleLive = false;				//presale toggle

	/**
	 * @param baseURI_ is the metadata root
	 * @param msgSigner_ is the verification address for allowlist validation
	 * @param teamAddrs_ are the team addresses
	 * @param teamShares_ are the team shares /10000
	 */
	constructor(
		string memory baseURI_, 
		address msgSigner_,
		address[6] memory teamAddrs_,
		uint256[6] memory teamShares_
	) 
		ERC721("RogueRhinos", "RYNO") 
	{
		baseURI = baseURI_;
		msgSigner = msgSigner_;

		for (uint256 i = 0; i < teamAddrs_.length; i++) {
			teamAddrs[i] = address(teamAddrs_[i]);
			teamShares[teamAddrs_[i]] = teamShares_[i];
		}
	}

	modifier saleIsLive {
		require(saleLive == true, "Sale not live");
		_;
	}

	modifier presaleIsLive {
		require(presaleLive == true, "Presale not live");
		_;
	}

	/**
	 * @notice allow contract to receive Ether
	 */
	receive() external payable {}

	//public
	/**
	 * @notice mint brand new RogueRhino nfts
	 * @param _numRhinos is the number of rhinos to mint
	 */
	function mintRhino(uint256 _numRhinos) public payable saleIsLive {
		require(tx.origin == msg.sender, "Humans only");
		require(_numRhinos > 0, "0 mint");
		require(_numRhinos < MINT_MAX, "20 max");
		require(msg.value == (_numRhinos * mintPrice), "Wrong ETH");

		_mintRhinos(msg.sender, _numRhinos);
	}

	/**
	 * @notice mint rhinos from the two allowlists.  
	 *  Raging Rhinos got rugged. If you held Raging (rugged) Rhinos
	 *  at the snapshot (Jan 25th 2022) you got on the Rogue allowlist.
	 * @dev you do not have to mint all your quota at once but 
	 *  you must pass the same sig and claimQuota each time you mint.
	 * @param _numToMint number of rhinos to mint in this call
	 * @param _sig allowlist signature
	 * @param _claimQuota initial allowlist quota to claim
	 * @param _listId 1 for raging rhino holder, 2 for public allowlist
	 */
	function rogueListMint(
		uint256 _numToMint,
		bytes calldata _sig,
		uint256 _claimQuota,
		uint256 _listId
	) 
		public
		payable
		presaleIsLive
	{
		//which allowlist is msg.sender in?
		if (_listId == 1) { //rogue allowlist
			require(msg.value == 0, "Wrong ETH");
		} else if (_listId == 2) { //public allowlist
			require(msg.value == (mintPrice * _numToMint), "Wrong ETH");
		} else { //for completeness
			revert("Bad listId");
		}

		require(tx.origin == msg.sender, "Humans only");
		require(_numToMint > 0, "0 mint");
		uint256 _minted = minted[msg.sender]; //local var for gas efficiency
		require(_numToMint + _minted <= _claimQuota, "Quota exceeded");
		require(legitSigner(_sig, _claimQuota, _listId), "Invalid sig");
		_minted += _numToMint;

		minted[msg.sender] = _minted;

		_mintRhinos(msg.sender, _numToMint);
	}

	/**
	 * @notice burn a rhino :(
	 * @notice whyyyyyy??
	 * @param _rhinoId token ID to be burned
	 */
	function burn(uint256 _rhinoId) external {
		require(
			_isApprovedOrOwner(msg.sender, _rhinoId), 
			"Wallet not approved to burn"
		);
		_burn(_rhinoId);
	}

	/**
	 * @dev future utility may demand burning 
	 *  via a trusted deity contract
	 * @param _rhinoId the rhino to burn
	 */
	function deityBurn(uint256 _rhinoId) external {
		require(deityAddress != address(0), "Deity Address not set");
		require(
			_isApprovedOrOwner(tx.origin, _rhinoId) 
			&& msg.sender == deityAddress,
			"Can't burn this"
		);
		_burn(_rhinoId);
	}

	/**
	 * @notice list all the rhinos in a wallet
	 * @dev useful for staking in future utility
	 * @dev don't call from a contract or you'll 
	 *  ruin yourself with gas
	 */
    function walletOfOwner(address _addr) 
    public 
    virtual 
    view
    returns (uint256[] memory) 
    {
        uint256 ownerBal = balanceOf(_addr);
        if (ownerBal == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory tokenList = new uint256[](ownerBal);
            uint256 count;
            uint256 maxLoops = totalSupply;
            for (uint i = 0; i < maxLoops; i++) {
                bool exists = _exists(i);
                if (exists && ownerOf(i) == _addr) {
                    tokenList[count] = i;
                    count++;
                } else if (!exists && tokenList[ownerBal - 1] == 0) {
                    maxLoops++;
                }
            }
            return tokenList;
        }
    }

	/**
	 * @notice set the upgrade deity address
	 * @param _deityAddress is the trusted deity contract address
	 */
	function setDeityAddress(address _deityAddress) public onlyOwner {
		deityAddress = _deityAddress;
	}

	/**
	 * @param _newBaseURI will be set as the new baseURI
	 * for token metadata access
	 */
	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	/**
	 * @notice start or stop minting
	 */
	function toggleSale() public onlyOwner {
		saleLive = !saleLive;
	}

	/**
	 * @notice start or stop presale minting
	 */
	function togglePresale() public onlyOwner {
		presaleLive = !presaleLive;
	}

	/**
	 * @notice set a new sale mintPrice in WEI,
	 *  just in case eth does something ridiculous.
	 * @dev be sure to set the new mintPrice in WEI
	 * @notice again, make sure you set this in WEI!
	 * @notice 1 eth == 1*10^18 wei
	 * @param _newWeiPrice the new mint mintPrice in WEI
	 */
	function setMintPrice(uint256 _newWeiPrice) public onlyOwner {
		mintPrice = _newWeiPrice;
	}

	/**
	 * @notice set a new msgSigner for allowlist validation
	 * @param _newSigner is the new signer address
	 */
	function setMsgSigner(address _newSigner) public onlyOwner {
		msgSigner = _newSigner;
	}

	/**
	 * @notice airdrop _num rhinos to _to
	 * @param _to recipient address
	 * @param _num number of rhinos
	 */
	function airdropRhinos(address _to, uint256 _num) public onlyOwner {
		require(reserveRhinos - _num > 0, "Reserve empty");
		reserveRhinos -= _num;
		_mintRhinos(_to, _num);
	}

	///withdraw to trusted wallets
	function withdraw() public {
		//team shares assigned in constructor are access keys
		require(teamShares[msg.sender] > 0, "Team only");
		uint256 bal = address(this).balance;

		for (uint256 mem = 0; mem < teamAddrs.length; mem++) {
			address adi = teamAddrs[mem];
			payable(adi).send(teamShares[adi] * bal / 10000);
		}
	}

	//internal
	/**
	 * @notice mint function called by multiple other functions
	 * @param _to recipient address
	 * @param _num number of rhinos to mint
	 */
	function _mintRhinos(address _to, uint256 _num) internal {
		uint256 _totalSupply = totalSupply; //temp var for gas efficiency
		require(_totalSupply + _num < MAX_RHINOS, "Too few Rhinos left!");

		for (uint256 r = 0; r < _num; r++) {
			unchecked { //overflow checked above
				_totalSupply++;
			}
			_safeMint(_to, _totalSupply); //trusted parent
		}
		totalSupply = _totalSupply;
	}

	///@notice override the _baseURI function in ERC721
	function _baseURI() 
	internal 
	view 
	virtual 
	override 
	returns (string memory) 
	{
		return baseURI;
	}

	//private
	/**
	 * @notice was the correct hash signed by the msgSigner?
	 * @param _sig the signed hash to inspect
	 * @dev _sig should be a signed hash of the sender, 
	 *  this contract, their quota and the whitelist id. 
	 *  The signer is recovered and compared to msgSigner for validity.
	 */
	function legitSigner(bytes memory _sig, uint256 _numToHash, uint256 _wlId)
	private 
	view
	returns (bool)
	{
		//hash the sender, this address, and a number
		//this should be the same hash as signed in _sig
		bytes32 checkHash = keccak256(abi.encodePacked(
			msg.sender,
			address(this),
			_numToHash,
			_wlId
		));

		bytes32 ethHash = ECDSA.toEthSignedMessageHash(checkHash);
		address recoveredSigner = ECDSA.recover(ethHash, _sig);
		return (recoveredSigner == msgSigner);
	}
}
