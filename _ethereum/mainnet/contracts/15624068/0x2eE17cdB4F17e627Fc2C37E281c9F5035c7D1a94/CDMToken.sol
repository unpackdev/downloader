// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.9;

/* 
    @author:        0xfd3495
    @www:           cyclechain.io
*/

import "./ERC20.sol";
import "./Ownable.sol";

// Debugging
// import "./console.sol";

contract CDMToken is ERC20, Ownable {
    /**
     * 
     * Token Allocation Wallets
     * 
     */

    //        name  => uint160(addr) | uint96(percent) 
    mapping (string => uint256) wallets;
    
    constructor() ERC20("Casino De Meta", "CDM") {
        _mint(msg.sender, 100_000_000 * 10 ** decimals());

        /**
         * Initiliaze wallets with percent for Token Allocation
         * 
         * @note: This section might be via deploy params
         */


        /**
         * Team wallet
         * 
         * @percent:                    12%
         * 
         */
        wallets["team"] = compose(0xD06AF999fed4213419c5bD23716F94E500A5d1d8, 12);

        /**
         * Seed sales Wallet
         * 
         * @percent:                    3%
         */
        wallets["seed_sale"] = compose(0x4202a81f7E80834FE0b117EAf8ef4A49416BE848, 3);
        
        

        /**
         * Private Sales Wallet
         * 
         * @percent:                    5%
         */
        wallets["private_sale"] = compose(0x5cff68cb84DfCEd2F4893dAEBD00c313262AD397, 5);
        

        /**
         * Public Sales Wallet
         * 
         * @percent:                    10%
         */
        wallets["public_sale"] = compose(0x8Ce5a7Cd9CcFDC7a3BA0f1d6347c770F9785ef87, 10);
        

        /**
         * Business Wallet
         * 
         * @percent:                    10%
         */
        wallets["business"] = compose(0xA5209f6caa6a9701dAECC0ed768b93E236888F1c, 10);


        /**
         * Marketing Wallet
         * 
         * @percent:                    10%
         */
        wallets["marketing"] = compose(0xe698e63712Db23Be29d5B648559313eAca481a7E, 10);


        /**
         * Rewards Wallet
         * 
         * @percent:                    40%
         */
        wallets["rewards"] = compose(0x60affF93A69b4F42154CAdab0a1d0633969415fa, 40);


        /**
         * LP Wallet
         * 
         * @percent:                    3%
         */
        wallets["lp"] = compose(0x934bf455FC0E52e58034c4ee3DD34CbFa400700E, 3);


        /**
         * Foundation Wallet
         * 
         * @percent:                    7%
         */
        wallets["foundation"] = compose(0x764989B4371A0Db90e039bd6c0F0409a8DbdB479, 7);
        


        multiTransfer();
    }

    function decimals() 
        public 
        pure 
        override 
        returns (uint8){
		return 6;
	}

    // Multi transfer
    function multiTransfer() 
        internal 
        onlyOwner{
        address owner = _msgSender();
        uint256 staticBalance = balanceOf(owner); // eq to totalSupply

        string[9] memory walletNames = ["team", "seed_sale", "private_sale", "public_sale", "business", "marketing", "rewards", "lp", "foundation"];

        for (uint i = 0; i < walletNames.length; i++) {
            (address wallet, uint96 percent) = raze(wallets[walletNames[i]]);
            
            uint256 value = 0;
            
            unchecked{
                value = staticBalance * uint256(percent * 10) / 1000;
            }

            _transfer(owner, wallet, value);
        }
    }

    function compose(address addr, uint96 percent) 
        internal 
        pure 
        returns(uint256){
        require(percent <= 100 && addr != address(0));
        return uint256(uint256(uint160(address(addr))) | uint256(uint96(percent)) << 160);
    }

    function raze(uint256 composedValue) 
        internal 
        pure 
        returns(address addr, uint96 percent){
        addr = address(uint160(uint256(composedValue)));
        percent = uint96(composedValue >> 160);
    }
}