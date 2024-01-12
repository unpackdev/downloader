// SPDX-License-Identifier: Unlicense
// Creator: 0xYeety; 1 yeet = 1 yeet
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC721.sol";

contract YNSS is ERC721, Ownable {
    using Strings for uint256;

    uint256 public _ynssMintPrice = 0.02 ether;

    mapping(uint256 => string) private tokenURIs;

    address private immutable gnssContractAddress;

    enum MintStatus {
        PreMint,
        Public
    }

    MintStatus public mintStatus = MintStatus.PreMint;

    mapping(address => uint256) private paymentInfo;

    uint256 totalReceived = 0;
    mapping(address => uint256) amountsWithdrawn;

    mapping(address => bool) uploadAuths;

    modifier onlyAuthorized() {
        _authorizedToUploadMetadata();
        _;
    }
    function _authorizedToUploadMetadata() internal view virtual {
        require(uploadAuths[msg.sender], "unauthorized");
    }

    modifier onlyPayee() {
        _isPayee();
        _;
    }
    function _isPayee() internal view virtual {
        require(paymentInfo[msg.sender] > 0, "not a royalty payee");
    }

    string collectionDescription = "YNSS is the Yenesis collection of 0xgorro and an homage to procedural art.";
    string collecImg = "https://ynss.mypinata.cloud/ipfs/QmXykNtVNuifLXegaLukf3R9K5RfAwibKtR7HBSwoWnJKd";
    string externalLink = "https://twitter.com/0xgorro";

    constructor (
        address _gnssContractAddress,
        string memory _name,
        string memory _symbol,
        address[] memory _payees,
        uint128[] memory _basisPoints
    ) ERC721(_name, _symbol) {
        gnssContractAddress = _gnssContractAddress;
        uploadAuths[msg.sender] = true;

        for (uint256 i = 0; i < _payees.length; i++) {
            paymentInfo[_payees[i]] = _basisPoints[i];
        }
    }

    function changeMintStatus(MintStatus _status) external onlyOwner {
        require(_status != MintStatus.PreMint);
        mintStatus = _status;
    }

    function preMint(address to, uint256[] memory gnssIds) public onlyAuthorized {
        require(mintStatus == MintStatus.PreMint, "n/pr");

        for (uint256 i = 0; i < gnssIds.length; i++) {
            require(to == IERC721(gnssContractAddress).ownerOf(gnssIds[i]), "n/o");
        }

        _safeMint(to, gnssIds);
    }

    function mintPublic(uint256[] memory gnssIds) public payable {
        require(mintStatus == MintStatus.Public, "n/pu");
        require(msg.value == _ynssMintPrice*(gnssIds.length), "v");

        for (uint256 i = 0; i < gnssIds.length; i++) {
            require(msg.sender == IERC721(gnssContractAddress).ownerOf(gnssIds[i]), "n/o");
        }

        totalReceived += msg.value;

        _safeMint(msg.sender, gnssIds);
    }

    //================//

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyAuthorized {
        require(_exists(tokenId), "z");

        tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "z");

        string memory toReturn = tokenURIs[tokenId];
        require(bytes(toReturn).length > 0, "L0");

        return toReturn;
    }

    //================//

    function setCollectionDescription(string memory _collectionDescription) public onlyOwner {
        collectionDescription = _collectionDescription;
    }

    function setCollecImg(string memory _collecImg) public onlyOwner {
        collecImg = _collecImg;
    }

    function setExternalLink(string memory _externalLink) public onlyOwner {
        externalLink = _externalLink;
    }

    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"YNSS\",",
                "\"description\":\"", collectionDescription, "\",",
                "\"image\":\"", collecImg, "\",",
                "\"external_link\":\"", externalLink, "\",",
                "\"seller_fee_basis_points\":500,\"fee_recipient\":\"",
                uint256(uint160(address(this))).toHexString(), "\"}"
            )
        );
    }

    //================//

    receive() external payable {
        totalReceived += msg.value;
    }

    function authorizeToUpload(address toAuthorize) public onlyOwner {
        uploadAuths[toAuthorize] = true;
    }

    function withdraw() public onlyPayee {
        uint256 totalForPayee = (totalReceived/10000)*paymentInfo[msg.sender];
        uint256 toWithdraw = totalForPayee - amountsWithdrawn[msg.sender];
        amountsWithdrawn[msg.sender] = totalForPayee;
        (bool success, ) = payable(msg.sender).call{value: toWithdraw}("");
        require(success, "Payment failed!");
    }
}
