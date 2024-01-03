pragma solidity >=0.6.0 <0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./STBU_Token.sol";

contract NFT is ERC721, Ownable {
    using SafeMath for uint256;

    StoboxToken private STBU;

    constructor(address payable _STBU) ERC721("Stobox Lucky NFT", "STOBOXNFT") public {
        STBU = StoboxToken(_STBU);
    }

    modifier StoboxTokenChecker(address _toCheck) {
        StoboxToken _STBU = STBU;
        require(_STBU.balanceOf(_toCheck) >= uint256(1000).mul((10 ** _STBU.decimals())), "NotEnoughSTBU");
        _;
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public override 
    StoboxTokenChecker(_from)
    StoboxTokenChecker(_to) {
        ERC721.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override 
    StoboxTokenChecker(_from)
    StoboxTokenChecker(_to) {
        ERC721.safeTransferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override 
    StoboxTokenChecker(_from)
    StoboxTokenChecker(_to) {
        ERC721.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function mint(address _to, uint256 _tokenId, string memory _tokenURI) external onlyOwner {
        require(ERC721.totalSupply() <= 10000, "TooMuchSupply");
        ERC721._mint(_to, _tokenId);
        ERC721._setTokenURI(_tokenId, _tokenURI);
    }
}