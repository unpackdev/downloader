// SPDX-License-Identifier: MIT
/*
     ██╗ ██╗ ███████╗ █████╗ ██╗   ██╗███████╗██╗   ██╗██╗  ██╗██████╗  █████╗ ██╗███╗   ██╗██╗ █████╗ ███╗   ██╗███████╗ ██████╗ ██╗     ██╗  ██╗
   ████████╗██╔════╝██╔══██╗██║   ██║██╔════╝██║   ██║██║ ██╔╝██╔══██╗██╔══██╗██║████╗  ██║██║██╔══██╗████╗  ██║██╔════╝██╔═══██╗██║     ██║ ██╔╝
  ╚██╔═██╔╝███████╗███████║██║   ██║█████╗  ██║   ██║█████╔╝ ██████╔╝███████║██║██╔██╗ ██║██║███████║██╔██╗ ██║█████╗  ██║   ██║██║     █████╔╝
 ████████╗╚════██║██╔══██║╚██╗ ██╔╝██╔══╝  ██║   ██║██╔═██╗ ██╔══██╗██╔══██║██║██║╚██╗██║██║██╔══██║██║╚██╗██║██╔══╝  ██║   ██║██║     ██╔═██╗
╚██╔═██╔╝███████║██║  ██║ ╚████╔╝ ███████╗╚██████╔╝██║  ██╗██║  ██║██║  ██║██║██║ ╚████║██║██║  ██║██║ ╚████║██║     ╚██████╔╝███████╗██║  ██╗
╚═╝ ╚═╝ ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝      ╚═════╝ ╚══════╝╚═╝  ╚═╝.org
*/
pragma solidity ^0.8.10;

import "./ERC721A.sol";

// Shadows Of Forgotten Ancestors is the first #SaveUkrainianFolk collection
contract ShadowsOfForgottenAncestors is ERC721A {
    string public constant NAME = "#SaveUkrainianFolk: Shadows Of Forgotten Ancestors";
    string public constant SYMBOL = "FOLK";
    string public constant FOLK_URI = "ipfs://bafkreiaes7fbuuv7srwth6vge6al7u2lifa2bnc5frgjt2nwgiwdshdqmu";
    uint256 public constant MAX_FOLKS = 150;
    uint256 public constant MAX_FOLKS_PER_HOLDER = 5;
    uint256 public constant PRICE_PER_FOLK = 0.1 ether;
    address public constant UNCHAIN_FUND = 0x10E1439455BD2624878b243819E31CfEE9eb721C;  // https://unchain.fund/
    address public constant TEAM = 0xb1D7daD6baEF98df97bD2d3Fb7540c08886e0299;
    uint256 public constant TEAM_SHARE_PERCENTAGE = 20;  // 80/20 donation logic
    uint256 public constant AIRDROP_FOLKS = 3;

    event Donated(uint256 toUnchainFund, uint256 toTeam);

    constructor() ERC721A(NAME, SYMBOL) {}

    function mint(uint256 quantity) external payable {
        require(totalSupply() + quantity <= MAX_FOLKS, "FOLKs Sold Out");
        require(balanceOf(msg.sender) + quantity <= MAX_FOLKS_PER_HOLDER, "Max FOLKs per address reached");
        require(msg.value == PRICE_PER_FOLK * quantity, "Wrong price");

        _safeMint(msg.sender, quantity);
    }

    /**
    * airdrop mints AIRDROP_FOLKS number of FOLKs for team and marketing purposes
    */
    function airdrop() external {
        require(msg.sender == TEAM, "russian ship, go fuck yourself!");

        _safeMint(msg.sender, AIRDROP_FOLKS);
    }

    /**
    * donate transfers ethers from contract to charity fund and team
    * 80% transfers directly to Unchain Fund (https://unchain.fund/) ETH address
    * teamSharePercentage (20%) goes to support our team and keep developing #SaveUkrainianFolk project
    */
    function donate() external {
        uint256 totalBalance = address(this).balance;
        require(totalBalance > 0 ether, "Contract have no ethers");

        uint256 teamBalance = totalBalance * TEAM_SHARE_PERCENTAGE / 100;  // 20%
        uint256 unchainFundBalance = totalBalance - teamBalance;  // 80%

        (bool successUnchainFundDonate, ) = UNCHAIN_FUND.call{ value: unchainFundBalance }("");
        (bool successTeamDonate, ) = TEAM.call{ value: teamBalance }("");
        require(successUnchainFundDonate && successTeamDonate, "Error on transfers");

        emit Donated(unchainFundBalance, teamBalance);
    }

    /**
    * tokenURI returns the same URI for every tokenId, because collection contains only one type of NFT
    */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return FOLK_URI;
    }
}
