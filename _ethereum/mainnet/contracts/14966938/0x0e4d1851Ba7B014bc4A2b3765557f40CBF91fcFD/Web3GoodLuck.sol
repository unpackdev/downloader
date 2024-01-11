// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC20.sol";

/*************************************************************************************
 *       _____                _         _                                       
 *      |_   _|              (_)       | |                                      
 *        | |     __      __  _   ___  | |__      _   _    ___    _   _         
 *        | |     \ \ /\ / / | | / __| | '_ \    | | | |  / _ \  | | | |        
 *       _| |_     \ V  V /  | | \__ \ | | | |   | |_| | | (_) | | |_| |        
 *      |_____|     \_/\_/   |_| |___/ |_| |_|    \__, |  \___/   \__,_|        
 *                                                 __/ |                        
 *                                                |___/                         
 *                                                _     _                  _    
 *          /\                                   | |   | |                | |   
 *         /  \        __ _    ___     ___     __| |   | |  _   _    ___  | | __
 *        / /\ \      / _` |  / _ \   / _ \   / _` |   | | | | | |  / __| | |/ /
 *       / ____ \    | (_| | | (_) | | (_) | | (_| |   | | | |_| | | (__  |   < 
 *      /_/    \_\    \__, |  \___/   \___/   \__,_|   |_|  \__,_|  \___| |_|\_\
 *                     __/ |                                                    
 *                    |___/      
 *************************************************************************************/
                                                                                 

contract Web3GoodLuck is ERC721A, Ownable {
    
    uint256 public thisIsYourLove = 50000000000000000;
    uint256 public freeLuck = 5000;
    uint256 public totalLucks = 10000;
    uint256 public pocketSize = 10;
    bool public luckActive = false;
    string public luckSource;
    constructor() ERC721A("Web3GoodLuck", "WGL") {}
    /**
     * a magic door
     * win win win
     * good good luck
     */
    function mint(uint256 num) external payable {
        uint256 inAirLucks = _totalMinted();
        require(luckActive, "be patient, luck is on the way");
        require(balanceOf(msg.sender) + num <= pocketSize, "leave some luck to others");
        require(inAirLucks+num <= totalLucks, "no more luck, try buy some from others");
        require(inAirLucks+num <= freeLuck || msg.value >= num * thisIsYourLove, "no more free luck. but you can buy some");
        _mint(msg.sender, num);
    }

    /**
     * good luck rains from above
     */
    function luckRain(address[] calldata addrs) external onlyOwner {
        uint256 inAirLucks = _totalMinted();
        require(addrs.length + inAirLucks <= totalLucks, "do not rain too hard");
        for (uint256 i = 0; i < addrs.length; i++) {
          _mint(addrs[i], 1);
        }
    }

    /**
     * I am broke
     */
    function trySomeLuck(uint256 num) external onlyOwner {
        uint256 inAirLucks = _totalMinted();
        require(inAirLucks+num <= totalLucks, "no more luck, try buy some from others");
        _mint(msg.sender, num);
    }

    /**
     * this is a button for good luch
     * once I press it
     * you can have your good luck
     */
    function goodLuck() external onlyOwner {
      luckActive = !luckActive;
    }

    /** 
     * Hungry now 
     * I need to buy a burger for me to keep me alive
     */
    function eatBurger() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success);
    }
    
    /**
     * Vitalik will visit me this weekend
     * I will buy a pizza for him
     */
    function eatPizza(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
    }

    /**
     * God says
     * let there be luck
     */
    function setLuckSource(string calldata source) external onlyOwner {
        luckSource = source;
    }

    /**
     * I am feeling good
     */
    function adjustLove(uint256 love) external onlyOwner {
        thisIsYourLove = love;
    }

   function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return luckSource;
    }
}