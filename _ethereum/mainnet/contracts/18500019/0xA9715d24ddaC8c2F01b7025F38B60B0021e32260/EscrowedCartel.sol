// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./CartelManager.sol";


/*

      @@          @@@@@        @@@@@@     @@@@    @@@     @@@               
   @@@@@@@@@      @@@@@+     @@@@@@@@@@   @@@@    @@@     @@@    @@@@@@@@@   
  @@@    @@@     @@@ @@@     @@@    @@@   @@@@    @@@@    @@@   +@@@    @@@  
 @@@@    @@@     @@@ @@@     @@@    @@@@  @@@@    @@@@@   @@@   @@@@    @@@@ 
 @@@@            @@@ @@@     @@@@         @@@@    @@@@@@  @@@   @@@@    @@@@ 
 @@@@           @@@   @@@      @@@@@      @@@@   @@@@ @@@ @@@   @@@@    @@@@ 
 @@@@          @@@@   @@@@      @@@@@     @@@@   @@@@ @@@@@@@   @@@@    @@@@ 
 @@@@           @@@   @@@          @@@@   @@@@    @@@  @@@@@@   #@@@    @@@@.
 @@@@     =@@  @@@@@@@@@@@   @@@    @@@   @@@@    @@@   @@@@@   @@@@    @@@@ 
 @@@@    @@@   @@@@@@@*@@@   @@@    @@@   @@@@    @@@    @@@@   @@@@    @@@@ 
 @@@@    @@@   @@@     @@@   @@@@@@@@@@   @@@@    @@@     @@@    @@@    @@@@ 
  @@@@@@@@@    @@@     @@@%    @@@@@..    @@@@   @@@@     @@@     @@@@@@@@@  
   @@@@@@                                                           @@@@@    
                                 @#  @@@  *@                                 
                          @@@@@@*           .@@@@@@#          
                                                                             
                    @@@@@    @@@   @@@@@ @@@@@@ @@@@@@  @@                     
                   @@  @@   @@@@   @  @@   @@   @@      @@                     
                   @@      @@  @@  @  @@   @@   @@      @@                     
                   @@      @@  @@  @=-@@   @@   @@@@@@  @@                     
                   @@  @@  @@@@@@  @ @@    @@   @@      @@                     
                   @@  @@  @@  @@  @  @@   @@   @@      @@                   
                     @@    #*  @#  @   @%  @@   @%%%%@  %@@@@@@      
                     

    website: https://www.casinocartel.xyz/
    twitter: https://twitter.com/CasinoCartel_
    discord: https://discord.com/invite/nwpuwBWryU
    docs:    https://casino-cartel.gitbook.io/casino-cartel/
*/


contract EscrowedCartel is ERC20, Ownable {
    using SafeMath for uint256;

    address public casinoManager;
    address public presaleManager;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    modifier onlyCasinoManager() {
        require(msg.sender == casinoManager, "Caller is not the casino manager");
        _;
    }

    modifier onlyPresaleManager() {
        require (msg.sender == presaleManager, "Caller is not the presale manager");
        _;
    }

    constructor() ERC20("Escrowed Cartel", "esCARTEL") {}

    function mintFromCasino(address to, uint256 amount) external onlyCasinoManager {
        _mint(to, amount);
    }

    function mintFromPresale(address to, uint256 amount) external onlyPresaleManager {
        _mint(to, amount);
    }

    function setCasinoManager(address _rewardManager) external onlyOwner {
        casinoManager = _rewardManager;
    }

    function setPresaleManager(address _presaleManager) external onlyOwner {
        presaleManager = _presaleManager;
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {

        if (from == address(0)) revert("ERC20: transfer from the zero address");
        if (to == address(0)) revert("ERC20: transfer to the zero address");
    
        if (to != address(casinoManager) || to != deadAddress) {
            revert("Escrowed token can only be transferred to reward manager or dead address");
        }
        
        super._transfer(from, to, amount);
    }


}