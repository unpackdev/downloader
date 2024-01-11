// "½▓▓▓▓æM        $▓▓|                                        7G▒▀▓█▓╗▄
//   ████▌M        ▐██│ `▓██▒∩   █▓░"   ▐▀│"  ▀██▓|   ▓▓Γ  ▄███▀╚*   ╙████▄
//   ║███b∩        ▐██∩  ▐██b  ▄█Ñ╙    S▓█▓Ω∞  ╙███y╓█╣╙ ╓████ƒ        ▀███▌,
//   ║███b∩        (██∩  ▐██b╔█▒Q       █▐▌M     ██▓V¢   ████⌠          ████M
//   ║▒▒▒b⌐        ▐▒▒∩  ▐▒▒b╚∩ ▓▒▓\    ▒j▒M     ▐█▒Ñ   (▒▒▒▒│          ║▒▒█▒M
//   ║▒▒▒bM        ▐▒▓∩  ╞▒▒bM   ▓▒▒\   ▒j▒M     ▐▒▒Ñ    ▒▒▒▒│          ▓▒▒▒½∩
//   ╘▒▒▒▒|        ▒▒Ñ∩  ╚▒▒░M    ╙▒▒∞⌐ ╙j░∩     ╘▒▒½¡   ╙▒▒▒NC        ╒▒▒▒▒╡
//    ╙║║║#▄     ,║║╜╛   «▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄,, ╙▒║║░▄     ,#║║║╠∩
//     └╙╚║║╜/##║║╠Ñ╙     '╙╚╙╚╠Ñ╙║║║╠║║║║║║╜╜╚║╜Ñ╚╙"""     ╙╙╚║║░#╠║║╚╠░∩
//         "(╚╚ⁿ"└                 "└  ╚╜Ñ∞╙                    """"""
//                                     └╛

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./CappedERC1155XRoyalty.sol";
import "./UkiyoPendantTicketChecker.sol";

contract UkiyoPendant is
    Ownable,
    CappedERC1155XRoyalty,
    UkiyoPendantTicketChecker
{
    uint256 private constant PENDANT_ID = 0;

    struct MintConfig {
        uint128 mintPrice;
        uint64 wlSaleStart;
        uint64 publicSaleStart;
    }

    MintConfig public mintConfig;

    constructor(
        uint128 mintPrice_,
        uint256 maxSupply_,
        address signerAddress_,
        address royaltyReceiver_,
        uint96 royaltyPercent_,
        string memory baseTokenUri_,
        string memory baseExtension_
    )
        CappedERC1155XRoyalty(
            "Ukiyo Founder's Pendant",
            "UKIYOFP",
            baseTokenUri_,
            baseExtension_
        )
        UkiyoPendantTicketChecker(signerAddress_)
    {
        mintConfig.mintPrice = mintPrice_;
        _setSupply(PENDANT_ID, maxSupply_);
        _updateRoyalty(royaltyReceiver_, royaltyPercent_);
    }

    modifier callerIsUser() {
        require(msg.sender == tx.origin, "Caller is contract!");
        _;
    }

    /************************
     **  Minting functions **
     ************************/

    function whitelistMint(bytes calldata signature)
        external
        payable
        callerIsUser
        validTicket(TicketType.WHITELIST, signature)
        withinLimit(PENDANT_ID, 1)
    {
        require(
            block.timestamp >= mintConfig.wlSaleStart &&
                block.timestamp < mintConfig.wlSaleStart + 1 days,
            "Whitelist sale not active!"
        );
        require(!whitelistMinted(PENDANT_ID, msg.sender), "Already minted");
        _setWhitelistMinted(PENDANT_ID, msg.sender);
        _mint(msg.sender, PENDANT_ID, 1, "");
        _refundIfOver(1);
    }

    function publicMint(bytes calldata signature)
        external
        payable
        callerIsUser
        validTicket(TicketType.PUBLIC, signature)
        withinLimit(PENDANT_ID, 1)
    {
        require(
            block.timestamp >= mintConfig.publicSaleStart &&
                block.timestamp < mintConfig.publicSaleStart + 1 days,
            "Public sale not active!"
        );
        require(!publicMinted(PENDANT_ID, msg.sender), "Already minted");
        _setPublicMinted(PENDANT_ID, msg.sender);
        _mint(msg.sender, PENDANT_ID, 1, "");
        _refundIfOver(1);
    }

    function _refundIfOver(uint256 quantity) private {
        uint256 price = quantity * mintConfig.mintPrice;
        require(msg.value >= price, "Need more ether!");

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /*******************************
     **  Administrative functions **
     *******************************/

    function setupWLSaleTime(uint64 _wlSaleStart) external onlyOwner {
        mintConfig.wlSaleStart = _wlSaleStart;
    }

    function setupPublicSaleTime(uint64 _publicSaleStart) external onlyOwner {
        mintConfig.publicSaleStart = _publicSaleStart;
    }

    function setSigner(address _signerAddress) external onlyOwner {
        _setSigner(_signerAddress);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to transfer");
    }

    function updateRoyalty(address _royaltyReceiver, uint96 _royaltyPercent)
        external
        onlyOwner
    {
        _updateRoyalty(_royaltyReceiver, _royaltyPercent);
    }

    function setBaseUri(string calldata baseUri) external onlyOwner {
        _setBaseUri(baseUri);
    }

    function setBaseExtension(string calldata baseExtension)
        external
        onlyOwner
    {
        _setBaseExtension(baseExtension);
    }

    function setPendantSupply(uint256 newSupply) external onlyOwner {
        require(
            newSupply < tokenMaxSupplies[PENDANT_ID],
            "New pendant supply must be less than current supply"
        );
        _setSupply(PENDANT_ID, newSupply);
    }

    // Mint remaining Pendants to wallet
    function devMint() external onlyOwner {
        require(
            block.timestamp < mintConfig.wlSaleStart ||
                block.timestamp >= mintConfig.wlSaleStart + 1 days,
            "Whitelist sale is active!"
        );
        require(
            block.timestamp < mintConfig.publicSaleStart ||
                block.timestamp >= mintConfig.publicSaleStart + 1 days,
            "Public sale is active!"
        );

        uint256 leftOver = tokenMaxSupplies[PENDANT_ID] -
            totalSupply(PENDANT_ID);
        require(leftOver > 0, "No pendants left!");

        _mint(msg.sender, PENDANT_ID, leftOver, "");
    }

    /****************************
     **  Aux data helpers      **
     **                        **
     **  Bits Layout:          **
     **  [0] `whitelistMinted` **
     **  [1] `publicMinted`    **
     ****************************/
    function _setWhitelistMinted(uint256 tokenId, address owner) private {
        uint64 aux = _getAux(tokenId, owner);
        _setAux(0, owner, aux |= 1);
    }

    function whitelistMinted(uint256 tokenId, address owner)
        public
        view
        returns (bool)
    {
        uint64 aux = _getAux(tokenId, owner);
        uint64 mask = 1;
        return (aux & mask) != 0;
    }

    function _setPublicMinted(uint256 tokenId, address owner) private {
        uint64 aux = _getAux(tokenId, owner);
        _setAux(0, owner, aux |= (1 << 1));
    }

    function publicMinted(uint256 tokenId, address owner)
        public
        view
        returns (bool)
    {
        uint64 aux = _getAux(tokenId, owner);
        uint64 mask = 1 << 1;
        return (aux & mask) != 0;
    }
}
