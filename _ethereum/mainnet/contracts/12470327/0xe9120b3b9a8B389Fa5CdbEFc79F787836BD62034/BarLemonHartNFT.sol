//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.4;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./HasSecondarySaleFees.sol";

contract BARLemonHartNFT is ERC1155, HasSecondarySaleFees, Ownable {

    event AddTokenInfo(uint256 indexed tokenId, string rawImageCid);

    struct TokenInfo {
        bool isPresent;
        bool isLimited;
        uint256 price;
        string metadataCid;
    }

    address payable private paymentRecipient;
    mapping(uint256 => TokenInfo) private tokenInfoList;
    uint256 public nextTokenId;
    string private _uri;

    constructor(
        address payable _paymentRecipient,
        address payable _royaltyRecipient
    ) ERC1155("") {
        require(_paymentRecipient != address(0), "Invalid address");
        require(_royaltyRecipient != address(0), "Invalid address");

        _uri = "https://cloudflare-ipfs.com/ipfs/";
        paymentRecipient = _paymentRecipient;
        address payable[] memory marketRoyaltyRecipients = new address payable[](1);
        marketRoyaltyRecipients[0] = _royaltyRecipient;
        uint256[] memory marketRoyaltyFees = new uint256[](1);
        marketRoyaltyFees[0] = 1000;

        _setDefaultRoyalty(marketRoyaltyRecipients, marketRoyaltyFees);
    }
    
    modifier isTokenInfoPresent(uint256 tokenId) {
        require(tokenInfoList[tokenId].isPresent, "Token info is not present");
        _;
    } 

    function isLimited(uint256 tokenId) external view isTokenInfoPresent(tokenId) returns(bool) {
        return tokenInfoList[tokenId].isLimited;
    }

    function price(uint256 tokenId) external view isTokenInfoPresent(tokenId) returns(uint256) {
        return tokenInfoList[tokenId].price;
    }

    function metadataCid(uint256 tokenId) external view isTokenInfoPresent(tokenId) returns(string memory) {
        return tokenInfoList[tokenId].metadataCid;
    }

    function addTokenInfoBatch(
        uint256[] calldata prices,
        string[] calldata metadataCidList,
        string[] calldata rawImageCidList
    ) external onlyOwner {
        require(prices.length == metadataCidList.length, "Arguments length is not matched");

        for (uint256 i = 0; i < prices.length; i++) {
            addTokenInternally(false, prices[i], metadataCidList[i], rawImageCidList[i]);
        }
    }

    function mintLimitedToken(
        string calldata _metadataCid,
        string calldata _rawImageCid,
        address recipient
    ) external onlyOwner {
        uint256 tokenId = nextTokenId;
        addTokenInternally(true, 0, _metadataCid, _rawImageCid);

        _mint(recipient, tokenId, 1, "");
    }

    function buy(uint256 tokenId, uint256 amount) external payable isTokenInfoPresent(tokenId) {
        TokenInfo memory tokenInfo = tokenInfoList[tokenId];
        require(!tokenInfo.isLimited, "Limited token info is not able to be purchased");
        require(msg.value >= (tokenInfo.price * amount), "Sent ether is insufficient");

        _mint(msg.sender, tokenId, amount, "");
    }
    
    function withdraw() external {
        payable(paymentRecipient).transfer(address(this).balance);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        TokenInfo memory tokenInfo = tokenInfoList[tokenId];
        require(tokenInfo.isPresent, "URI query for nonexistent token");

        return bytes(_uri).length > 0
        ? string(abi.encodePacked(_uri, tokenInfo.metadataCid))
        : '';
    }
    
    function setURI(string memory newURI) external onlyOwner {
        _uri = newURI;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155, HasSecondarySaleFees)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function addTokenInternally(
        bool _isLimited,
        uint256 _price,
        string calldata _metadataCid,
        string calldata _rawImageCid
    ) internal {
        TokenInfo memory tokenInfo = TokenInfo(true, _isLimited, _price, _metadataCid);

        tokenInfoList[nextTokenId] = tokenInfo;
        emit AddTokenInfo(nextTokenId, _rawImageCid);
        nextTokenId += 1;
    }
}

