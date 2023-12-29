// SPDX-License-Identifier: MIT
//  @@@@@@@@@@@@@@@@@@@@@@@@@        &   &@@@@@@@@@@@@@@@@@@@@@@@@@@    #@@@@     #@@@@@@@,       &@@@@@@@@@@@@@@@@@@@@@@@@@@/       /@@@@@@@/             &
//  %%%%%%%%%%%%%%%%%%%%%%&@@@&    @@@   #%%%%%%%%%&@@@%%%%%%%%%%%    &@@@@    &@@@@@&&@@@@@@.    #%%%%%%%%%%%%%%%%%%%%%%%%%%*    /@@@@@@%@@@@@@(          &@@.
//                         @@@@   #@@@             ,@@@             &@@@&    @@@@%        (@@@/                                  %@@@,        @@@@#        &@@#
//  %@@@@@@@@@@@@@@@@@@@@@@@@@    #@@@             ,@@@           @@@@%   .@@@@#           %@@&   *@@@@@@@@@@@@@@@@@@@@@@@@@@/  .@@@*           @@@@%      &@@#
//  @@@*                   /@@@   #@@@             ,@@@         @@@@#   .@@@@(             %@@&   &@@&                          .@@@*             &@@@&    &@@#
//   @@,  .@@@@@@@@@@@@@@@@@@@&   #@@@             ,@@@      .@@@@#   ,@@@@/               %@@&   #@@@@@@@@@@@@@@@@@@@@@@@@@@/  .@@@*               %@@@@  &@@#
//     ,  .@@@@@@@@@@@@@@@@@,     #@@@             ,@@@    .@@@@(   *@@@@*                 %@@&     #@@@@@@@@@@@@@@@@@@@@@@@@/  .@@@*                 #@@@@&@@#
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

abstract contract BitmenAvatarContract {
    function mintTransfer(address to) public virtual returns (uint256);
}

abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract EVOWAREContract is ERC1155, Ownable, ERC1155Burnable {
    using SafeMath for uint256;
    string private _uri;
    uint256 tokenId = 0;
    uint256 amountMinted = 0;
    uint256 limitAmount = 729;
    uint256 public immutable maxTeamAmount = 50;
    uint256 public teamMintedAmount;
    address bitmenAvatarContractAddress;
    address saleAddress;
    bool getAvatarStarted = false;

    constructor()
        ERC1155("ipfs://QmTHeULW9ebRQmLRU4H2xqsRRP2hFcHRiHdbEWHt7Z24K1")
    {}

    modifier canTeamMint(uint256 numberOfTokens) {
        uint256 ts = teamMintedAmount;
        require(
            ts + numberOfTokens <= maxTeamAmount,
            "Purchase would exceed max team tokens"
        );
        _;
    }

    function toggleGetAvatar() public onlyOwner {
        getAvatarStarted = !getAvatarStarted;
    }

    function mint(
        uint256 tknId,
        uint256 n,
        address to
    ) public payable returns (uint256) {
        require(msg.sender == saleAddress, "Not authorized");
        uint256 amount = n;
        require(
            amount + amountMinted <= limitAmount,
            "Mint would exceed max tokens"
        );
        amountMinted = amountMinted + amount;
        _mint(to, tknId, amount, "");
        return tknId;
    }

    function adminMint(uint256 n) public onlyOwner canTeamMint(n) {
        require(
            n + amountMinted <= limitAmount,
            "Mint would exceed max tokens"
        );
        amountMinted = amountMinted + n;
        _mint(msg.sender, tokenId, n, "");
    }

    function getAvatarToken(uint256 id) public returns (uint256) {
        require(getAvatarStarted == true, "Get Avatar has not started");
        require(balanceOf(msg.sender, id) > 0, "Balance must greater than 0");
        burn(msg.sender, id, 1);
        BitmenAvatarContract bContract = BitmenAvatarContract(
            bitmenAvatarContractAddress
        );
        uint256 mintedId = bContract.mintTransfer(msg.sender);
        return mintedId;
    }

    function adminGetAvatarToken(uint256 id) public onlyOwner {
        require(balanceOf(msg.sender, id) > 0, "Balance must greater than 0");
        burn(msg.sender, id, 1);
        BitmenAvatarContract bContract = BitmenAvatarContract(
            bitmenAvatarContractAddress
        );
        bContract.mintTransfer(msg.sender);
    }

    function getAmountMinted() public view returns (uint256) {
        return amountMinted;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function setBitmenAvatarContractAddress(address newAddress)
        public
        onlyOwner
    {
        bitmenAvatarContractAddress = newAddress;
    }

    function setSaleAddress(address newAddress) public onlyOwner {
        saleAddress = newAddress;
    }

    function setUri(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
}
