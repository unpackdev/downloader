// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VRFConsumerBase.sol";
import "./IERC20.sol"; 	// ERC20 interface
import "./ERC721.sol"; 	// ERC721
import "./Ownable.sol"; 		// OZ: Ownable
import "./SafeMath.sol"; 	// OZ: SafeMath
import "./ReentrancyGuard.sol"; 	// OZ: ReentrancyGuard 
import "./EnumerableSet.sol";	// OZ: EnumerableSet

contract EcoNFT is ERC721, VRFConsumerBase, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Strings for string;
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public constant PINO_NFT_SIZE = 1080;
    uint256 public constant TERU_NFT_LEVEL_LEN = 5;
    bool public is_synthetic; // synthetics opened 
    bytes32 internal immutable keyHash;
    EnumerableSet.UintSet internal mintedTokenIds;
    uint256 internal fee;
    uint256 public mintSize;
    uint256 public startIndex; //inclusive
    uint256 public endIndex; //exclusive
    uint256 public pinoStartIndex; //inclusive
    uint256 public pinoEndIndex; //exclusive
    uint256 public airdropStartIndex; //inclusive
    uint256 public syntheticStartIndex; //inclusive
    uint256 public boxSold; 
    uint256 public nftMinted; 
    uint256 public pinoNftMinted; 
    uint256 public airdropNftMinted; 
    uint256 public mintFeeETH; 
    uint256 public mintFeeToken; 
    uint256 public pinoMintFeeETH; 
    uint256 public pinoMintFeeToken; 
    address public teamWallet;
    address public immutable VRFCoordinator;
    IERC20 public immutable LinkToken;
    IERC20 public immutable EsgToken;

    mapping(uint256 => uint256) public levels;
    mapping(bytes32 => address) requestToSender;
    mapping (uint256 => address) internal depositOf;
    /**
     * Events
     */
    event BuyLuckyBoxETH(address indexed account, bytes32 requestId, uint256 cost);
    event BuyLuckyBoxESG(address indexed account, bytes32 requestId, uint256 cost);
    event VRFCallback(bytes32 indexed requestId, uint256 randomNumber, uint256 tokenId);
    event NFTSyntheticed(address indexed pinoNftOwner, uint256 indexed pinoTokenId, uint256 indexed teruTokenId, uint256 tokenId, uint256 teruNftLevel);

    /**
     * Constructor inherits VRFConsumerBase
     *
     */
    constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyhash, address _esgToken)
        VRFConsumerBase(_VRFCoordinator, _LinkToken)
        ERC721("TeTeru NFT", "TeTeru NFT")
    {   
        VRFCoordinator = _VRFCoordinator;
        LinkToken = IERC20(_LinkToken);
        keyHash = _keyhash;
	EsgToken = IERC20(_esgToken);
        fee = 0.1 * 10**18; // 0.1 LINK
	mintSize = 1000;
	startIndex = 0;
	endIndex = 1000;
	pinoStartIndex = 10000;
	pinoEndIndex = 11000;
	airdropStartIndex = 20000;
	syntheticStartIndex = 30000;
	airdropNftMinted = 0;
	pinoNftMinted = 0;
	mintFeeETH = 0.3 * 10**18; //0.3 ETH
	mintFeeToken = 476 * 10**18; //320 ESG 
	pinoMintFeeETH = 0.08 * 10**18; //0.1 ETH
	pinoMintFeeToken = 158 * 10**18; //120 ESG 
	teamWallet = 0x9e3ee009c2E8103Fb2D358d64C80249eF108e33B;
	is_synthetic = false;
    }
    function getLevelById(uint256 id) internal pure returns(uint256){
	if(id<410)
		return 1;
	if(id<740)
		return 2;
	if(id<910)
		return 3;
	if(id<990)
		return 4;
	if(id<1000)
		return 5;
	return 0;
    }

    //buy a lucky box
    function requestNewRandomNFTETH(address referrer) public payable nonReentrant returns (bytes32) {
        require(
            LinkToken.balanceOf(address(this)) >= fee,
            "Not enough LINK"
        );
        require(
            referrer != address(0),
            "Invalid referrer"
        );
	require(msg.value >= mintFeeETH, "INSUFFICIENT MINT COST ETH");
        bytes32 requestId = requestRandomness(keyHash, fee);
        requestToSender[requestId] = msg.sender;
	boxSold = boxSold.add(1);
	payable(referrer).transfer(msg.value.div(20));
	payable(teamWallet).transfer(msg.value.mul(19).div(20));
	emit BuyLuckyBoxETH(msg.sender, requestId, msg.value);
        return requestId;
    }

    function requestNewRandomNFTToken(address referrer) public nonReentrant returns (bytes32) {
        require(
            LinkToken.balanceOf(address(this)) >= fee,
            "Not enough LINK"
        );
        require(
            referrer != address(0),
            "Invalid referrer"
        );
	require(EsgToken.balanceOf(msg.sender) >= mintFeeToken, "INSUFFICIENT MINT COST TOKEN");
	EsgToken.transferFrom(msg.sender, address(this), mintFeeToken);

        bytes32 requestId = requestRandomness(keyHash, fee);
        requestToSender[requestId] = msg.sender;
	boxSold = boxSold.add(1);
	EsgToken.transfer(referrer, mintFeeToken.div(20));
	EsgToken.transfer(teamWallet, mintFeeToken.mul(19).div(20));
	emit BuyLuckyBoxESG(msg.sender, requestId, mintFeeToken);
        return requestId;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        uint256 newId = (randomNumber % mintSize);
	if(_exists(newId))
	{
		for(uint256 i=startIndex; i < endIndex; i++)
		{
			if(!_exists(i))
			{
				newId = i;
				break;
			}
		}
		require(!_exists(newId), "BOX SOLD OUT");
	}
	nftMinted = nftMinted.add(1);
	levels[newId] = getLevelById(newId);
        _safeMint(requestToSender[requestId], newId);
	EnumerableSet.add(mintedTokenIds, newId);	
	emit VRFCallback(requestId, randomNumber, newId);
    }

    /**
     * @notice Synthetic two kinds of NFT to one Gold NFT(Teru and Pino)
     * @param pinoTokenId The tokenId of Pino NFT to be deposited
     * @param teruTokenId The tokenId of Teru NFT to be deposited
     * @return Success indicator for success 
     */
    function synthetic(uint256 pinoTokenId, uint256 teruTokenId) external nonReentrant returns (bool) {
	require(is_synthetic == true, "sythentic is not open.");

	uint256 pinoNftLevel = EcoNFT(address(this)).getLevel(pinoTokenId);
	require(pinoNftLevel == 0, "Pino NFT accepted.");
    	require(depositOf[pinoTokenId] == address(0), "Pino token already sythenticed");
	address pinoNftOwner = EcoNFT(address(this)).ownerOf(pinoTokenId);
	EcoNFT(address(this)).safeTransferFrom(pinoNftOwner, address(this), pinoTokenId);
	depositOf[pinoTokenId] = pinoNftOwner;

	uint256 teruNftLevel = EcoNFT(address(this)).getLevel(teruTokenId);
	require(teruNftLevel > 0, "Teru NFT accepted.");
    	require(depositOf[teruTokenId] == address(0), "Teru token already sythenticed");
	address teruNftOwner = EcoNFT(address(this)).ownerOf(teruTokenId);
	EcoNFT(address(this)).safeTransferFrom(teruNftOwner, address(this), teruTokenId);
	depositOf[teruTokenId] = teruNftOwner;

	uint256 aStartIndex = syntheticStartIndex;
	uint256 newId =  aStartIndex.add(1);
	require(!_exists(newId), "NFT minted.");
	nftMinted = nftMinted.add(1);
        _safeMint(msg.sender, newId);
	EnumerableSet.add(mintedTokenIds, newId);	
	levels[newId] = teruNftLevel.add(TERU_NFT_LEVEL_LEN);

	emit NFTSyntheticed(pinoNftOwner, pinoTokenId, teruTokenId, newId, teruNftLevel);

	return true;
    }

    function airdropMint(address receipient)
	external
	onlyOwner
    {
	uint256 aStartIndex = airdropStartIndex.add(airdropNftMinted);
	for(uint256 i=0; i < 20; i++)
	{
		uint256 newId =  aStartIndex.add(i);
		require(!_exists(newId), "NFT minted.");
		nftMinted = nftMinted.add(1);
		airdropNftMinted = airdropNftMinted.add(1);
		levels[newId] = 0;
        	_safeMint(receipient, newId);
		EnumerableSet.add(mintedTokenIds, newId);	
	}
    }

    function pinoMintETH(address referrer, address receipient) public payable nonReentrant
    {
	require(referrer != address(0), "invalid address");
	require(receipient != address(0), "invalid address");

	require(msg.value >= pinoMintFeeETH, "INSUFFICIENT MINT COST ETH");

	uint256 newId = pinoStartIndex.add(pinoNftMinted); 
	require(newId < pinoEndIndex, "tokenId exceeds limit");
	require(!_exists(newId), "NFT minted.");
	nftMinted = nftMinted.add(1);
	pinoNftMinted = pinoNftMinted.add(1);
	payable(referrer).transfer(msg.value.div(20));
	payable(teamWallet).transfer(msg.value.mul(19).div(20));
	levels[newId] = 0;
        _safeMint(receipient, newId);
	EnumerableSet.add(mintedTokenIds, newId);	
    }

    function pinoMintToken(address referrer, address receipient) public nonReentrant
    {
	require(referrer != address(0), "invalid address");
	require(receipient != address(0), "invalid address");

	require(EsgToken.balanceOf(msg.sender) >= pinoMintFeeToken, "INSUFFICIENT MINT COST TOKEN");
	EsgToken.transferFrom(msg.sender, address(this), pinoMintFeeToken);

	uint256 newId = pinoStartIndex.add(pinoNftMinted); 
	require(newId < pinoEndIndex, "tokenId exceeds limit");
	require(!_exists(newId), "NFT minted.");
	nftMinted = nftMinted.add(1);
	pinoNftMinted = pinoNftMinted.add(1);
	EsgToken.transfer(referrer, pinoMintFeeToken.div(20));
	EsgToken.transfer(teamWallet, pinoMintFeeToken.mul(19).div(20));
	levels[newId] = 0;
        _safeMint(receipient, newId);
	EnumerableSet.add(mintedTokenIds, newId);	
    }

    function getLevel(uint256 tokenId) public view returns (uint256) {
        return levels[tokenId];
    }

    function getNumberOfBoxSold() external view returns (uint256) {
        return boxSold; 
    }

    function getMintedNFTLength() external view returns (uint256) {
	return EnumerableSet.length(mintedTokenIds);	
    }

    function getMintedNFT(uint256 index) external view returns (uint256) {
	return EnumerableSet.at(mintedTokenIds, index);	
    }

    /// @notice Returns metadata about a token (depending on randomness reveal status)
    /// @dev Partially implemented, returns only example string of randomness-dependent content
    function tokenURI(uint256 tokenId) override public pure returns (string memory) {
        string[2] memory parts;

        parts[0] = 'https://econft.market/service/meta.php?id=';

        parts[1] = string(tokenId.toString());

        string memory output = string(abi.encodePacked(parts[0], parts[1]));

        return output;
    }

    function tokenURIExtend(uint256 tokenId) public pure returns (string memory, string memory) {

        string[3] memory parts;

        parts[0] = 'https://econft.market';

        parts[1] = '/service/meta.php?id=';

        parts[2] = string(tokenId.toString());

        string memory api = string(abi.encodePacked(parts[1], parts[2]));

        return (parts[0], api);
    }


   // admin functions
   function _setMintSize(uint256 size) public onlyOwner {
	require(size != 0);
   	mintSize = size;
   }

   function _setStartIndex(uint256 startId) public onlyOwner {
   	startIndex = startId;
   }

   function _setEndIndex(uint256 endId) public onlyOwner {
	require(endId != 0);
   	endIndex = endId;
   }

   function _setLevelsMap(uint256[] memory ids, uint256[] memory lvs) public onlyOwner {
	require(ids.length != 0 && ids.length == lvs.length);
	for(uint256 i=0; i< ids.length; i++)
		levels[ids[i]] = lvs[i];
   }

   function _setMintFeeETH(uint256 _mintFee) public onlyOwner {
	require(_mintFee != 0);
	mintFeeETH = _mintFee;
   }

   function _setMintFeeToken(uint256 _mintFee) public onlyOwner {
	require(_mintFee != 0);
	mintFeeToken = _mintFee;
   }

   function _setPinoMintFeeETH(uint256 _mintFee) public onlyOwner {
	require(_mintFee != 0);
	pinoMintFeeETH = _mintFee;
   }

   function _setPinoMintFeeToken(uint256 _mintFee) public onlyOwner {
	require(_mintFee != 0);
	pinoMintFeeToken = _mintFee;
   }

   function _setTeamWallet(address _wallet) public onlyOwner {
	require(_wallet != address(0));
	teamWallet = _wallet;
   }

   function _withdrawERC20Token(address token) public onlyOwner {
	uint256 amount = IERC20(token).balanceOf(address(this));
	if(amount > 0)
		IERC20(token).transfer(teamWallet, amount);
   }

   function _withdrawETH() public onlyOwner {
	uint256 amount = address(this).balance; 
	if(amount > 0)
		payable(teamWallet).transfer(amount);
   }

    /**
     * @notice Update synthetic status 
     * @param flag If synthetic should be opened.
     */
    function _updateIsSynthetic(bool flag) external onlyOwner {
	is_synthetic = flag;
    }
   function _setPinoEndIndex(uint256 endId) public onlyOwner {
   	pinoEndIndex = endId;
   }
}
