// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./ERC721.sol";
import "./Base64.sol";
import "./OperatorFilterer.sol";


contract Sofa is ERC721, OperatorFilterer, Ownable, ERC2981 {
    bool public operatorFilteringEnabled;

    constructor() ERC721("Sofa Vision", "Sofa Vision") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = false;
        _setDefaultRoyalty(msg.sender, 450);
        _safeMint(owner(), 1);
    }

    string public BASE_URI = "";
    
    uint256 public revealStartTime = 1700485200;
    function setRevealStartTime(uint256 startTime) public onlyOwner {
        revealStartTime = startTime;
    }

    bool public paused = false;
    event RevealMinted(address owner, uint256 tokenId);

    function setBaseUri(string memory uri) public onlyOwner {
        BASE_URI = uri;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    address public revealer;

    function setRevealer(address addr) public onlyOwner {
        revealer = addr;
    }

    function revealMint(address wallet, uint256 tokenId) external {
        require(paused == false, "reveal not running");
        require(block.timestamp >= revealStartTime, "reveal not start");
        require(msg.sender == revealer, "u cannot mint without reveal!");
        _safeMint(wallet, tokenId);
        emit RevealMinted(wallet, tokenId);
    }

    function _safeMint(address wallet, uint256 tokenId) internal override {
        // mint
        super._safeMint(wallet, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    //for ERC2981 Opensea
    function contractURI() external view virtual returns (string memory) {
        return _formatContractURI();
    }

    //make contractURI
    function _formatContractURI() internal view returns (string memory) {
        (address receiver, uint256 royaltyFraction) = royaltyInfo(0, _feeDenominator()); //tokenid=0
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"seller_fee_basis_points":',
                                Strings.toString(royaltyFraction),
                                ', "fee_recipient":"',
                                Strings.toHexString(uint256(uint160(receiver)), 20),
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}
