// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//         _ _____ ____   ___    __    __      _ _                        //
//        / |___  |___ \ / _ \  / / /\ \ \_ __(_) |_ ___ _ __ ___         //
//        | |  / /  __) | (_) | \ \/  \/ / '__| | __/ _ \ '__/ __|        //
//        | | / /  / __/ \__, |  \  /\  /| |  | | ||  __/ |  \__ \        //
//        |_|/_/  |_____|  /_/    \/  \/ |_|  |_|\__\___|_|  |___/        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////

contract SevenTeenTwentyNineWritersCohort2 is ERC20, ERC20Burnable, Ownable {
    //
    constructor() ERC20("1729Writers Cohort 2", "1729W2") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
