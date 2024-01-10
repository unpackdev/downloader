// SPDX-License-Identifier: MIT

/*
                                          «∩ⁿ─╖
                                       ⌐  ╦╠Σ▌╓┴                        .⌐─≈-,
                                ≤╠╠╠╫╕╬╦╜              ┌"░░░░░░░░░░≈╖φ░╔╦╬░░Σ╜^
                               ¼,╠.:╬╬╦╖╔≡p               "╙φ░ ╠╩╚`  ░╩░╟╓╜
                                   Γ╠▀╬═┘`                         Θ Å░▄
                      ,,,,,        ┌#                             ]  ▌░░╕
             ,-─S╜" ,⌐"",`░░φ░░░░S>╫▐                             ╩  ░░░░¼
            ╙ⁿ═s, <░φ╬░░φù ░░░░░░░░╬╠░░"Zw,                    ,─╓φ░Å░░╩╧w¼
            ∩²≥┴╝δ»╬░╝░░╩░╓║╙░░░░░░Åφ▄φ░░╦≥░⌠░≥╖,          ,≈"╓φ░░░╬╬░░╕ {⌐\
            } ▐      ½,#░░░░░╦╚░░╬╜Σ░p╠░░╬╘░░░░╩  ^"¥7"""░"¬╖╠░░░#▒░░░╩ φ╩ ∩
              Γ      ╬░⌐"╢╙φ░░▒╬╓╓░░░░▄▄╬▄░╬░░Å░░░░╠░╦,φ╠░░░░░░-"╠░╩╩  ê░Γ╠
             ╘░,,   ╠╬     '░╗Σ╢░░░░░░▀╢▓▒▒╬╬░╦#####≥╨░░░╝╜╙` ,φ╬░░░. é░░╔⌐
              ▐░ `^Σ░▒╗,   ▐░░░░░ ▒░"╙Σ░╨▀╜╬░▓▓▓▓▓▓▀▀░»φ░N  ╔╬▒░░░"`,╬≥░░╢
               \  ╠░░░░░░╬#╩╣▄░Γ, ▐░,φ╬▄Å` ░ ```"╚░░░░,╓▄▄▄╬▀▀░╠╙░╔╬░░░ ½"
                └ '░░░░░░╦╠ ╟▒M╗▄▄,▄▄▄╗#▒╬▒╠"╙╙╙╙╙╙╢▒▒▓▀▀░░░░░╠╦#░░░░╚,╩
                  ¼░░░░░░░⌂╦ ▀░░░╚╙░╚▓▒▀░░░½░░╠╜   ╘▀░░░╩╩╩,▄╣╬░░░░░╙╔╩
                    ╢^╙╨╠░░▄æ,Σ ",╓╥m╬░░░░░░░Θ░φ░φ▄ ╬╬░,▄#▒▀░░░░░≥░░#`
                      *╓,╙φ░░░░░#░░░░░░░#╬╠╩ ╠╩╚╠╟▓▄╣▒▓╬▓▀░░░░░╩░╓═^
                          `"╜╧Σ░░░Σ░░░░░░╬▓µ ─"░░░░░░░░░░╜░╬▄≈"
                                    `"╙╜╜╜╝╩ÅΣM≡,`╙╚░╙╙░╜|  ╙╙╙┴7≥╗
                                                   `"┴╙¬¬¬┴┴╙╙╙╙""
*/

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ICIGAR.sol";

contract CIGAR is ICIGAR, ERC20, Ownable {
    uint256 public constant DAO_AMOUNT = 600000000000 ether;
    uint256 public constant LIQUIDITY_AMOUNT = 150000000000 ether;
    uint256 public constant TEAM_AMOUNT = 450000000000 ether;
    uint256 public constant PUBLIC_SALE_AMOUNT = 300000000000 ether;
    uint256 public constant STAKING_AMOUNT = 1500000000000 ether;
    uint256 public constant TOTAL_AMOUNT = 3000000000000 ether;

    // price per 1 ether tokens
    uint256 public mintPrice = .00001 ether;
    // max number of tokens to mint in one tx in ether
    uint256 public maxMint = 10000;

    uint256 public immutable timeStarted;
    uint256 public teamValueMinted;
    uint256 public publicSaleMinted;
    uint256 public totalMinted;

    bool public saleIsActive;

    bool public areControllersLocked;

    // a mapping from an address to whether or not it can mint / burn
    mapping(address => bool) public controllers;

    constructor() ERC20("CIGAR", "CIGAR") {
        timeStarted = block.timestamp;
    }

    function publicSaleMint(address to, uint256 amountInEther) external override payable {
        require(saleIsActive, "Sale is not active");
        uint256 amountInWei = amountInEther * 1 ether;
        require(publicSaleMinted + amountInWei <= PUBLIC_SALE_AMOUNT, "The public sale cap has been reached");
        require(amountInEther <= maxMint, "Amount requested is greater than max mint");
        require(amountInEther * mintPrice == msg.value, "Given ether does not match price required");

        _mint(to, amountInWei);
        publicSaleMinted += amountInWei;
        totalMinted += amountInWei;
    }

    function mint(address to, uint256 amount) external override {
        require(controllers[msg.sender], "Only controllers are allowed to mint");
        totalMinted += amount;
        require(totalMinted <= TOTAL_AMOUNT, "Max CIGAR reached");
        _mint(to, amount);
    }

    function reserveToDAO(address dao) external override onlyOwner {
        totalMinted += DAO_AMOUNT;
        _mint(dao, DAO_AMOUNT);
    }

    function reserveToLiquidity(address liquidityHandler) external override onlyOwner {
        totalMinted += LIQUIDITY_AMOUNT;
        _mint(liquidityHandler, LIQUIDITY_AMOUNT);
    }

    function reserveToTeam(address team) external override onlyOwner {
        require(teamValueMinted < TEAM_AMOUNT, "Team amount has been fully vested");
        uint256 quarter = 13 * (1 weeks);
        uint256 quarterNum = (block.timestamp - timeStarted) / quarter;
        require(quarterNum > 0, "A quarter has not passed");
        uint256 quarterAmount = TEAM_AMOUNT / 4;
        require(quarterNum * quarterAmount > teamValueMinted, "Quarter value already minted");

        uint256 amountToMint = (quarterNum * quarterAmount) - teamValueMinted;
        totalMinted += amountToMint;
        teamValueMinted += amountToMint;
        _mint(team, amountToMint);
    }

    function burn(address from, uint256 amount) external override {
        require(controllers[msg.sender], "Only controllers are allowed to burn");
        _burn(from, amount);
    }

    function addController(address controller) external override onlyOwner {
        require(!areControllersLocked, 'Controllers have been locked! No more controllers allowed.');
        controllers[controller] = true;
    }

    function removeController(address controller) external override onlyOwner {
        require(!areControllersLocked, 'Controllers have been locked! No more changes allowed.');
        controllers[controller] = false;
    }

    function flipSaleState() external override onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setMintPrice(uint256 _mintPrice) external override onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMint(uint256 _maxMint) external override onlyOwner {
        maxMint = _maxMint;
    }

    function lockControllers() external override onlyOwner {
        areControllersLocked = true;
    }

    function withdrawPublicSale() external override onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}