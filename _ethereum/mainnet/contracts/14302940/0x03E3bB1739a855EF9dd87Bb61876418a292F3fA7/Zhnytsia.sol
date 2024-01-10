/*

 _____   __                __       _      
/__  /  / /_  ____  __  __/ /______(_)___ _
  / /  / __ \/ __ \/ / / / __/ ___/ / __ `/
 / /__/ / / / / / / /_/ / /_(__  ) / /_/ / 
/____/_/ /_/_/ /_/\__, /\__/____/_/\__,_/  
                 /____/                   
                 
nsiu / myk31 / shahruz

*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "./ERC1155.sol";
import "./Ownable.sol";

contract Zhnytsia is ERC1155, Ownable {
    string public name = "ZHNYTSIA";
    string public symbol = "ZHNYTSIA";

    uint256 public immutable MAX_SUPPLY;
    uint256 public immutable MINT_FEE;
    uint256 public totalSupply;

    error IncorrectAmount();
    error MaxMinted();

    constructor(uint256 maxSupply, uint256 mintFee) {
        MAX_SUPPLY = maxSupply;
        MINT_FEE = mintFee;
    }

    function mint() public payable {
        if (msg.value != MINT_FEE) revert IncorrectAmount();
        if (totalSupply == MAX_SUPPLY) revert MaxMinted();
        unchecked {
            totalSupply++;
        }
        _mint(msg.sender, 1, 1, "");
    }

    function withdraw() public {
        (bool success, ) = address(0x3ae285B8f6ADcf9C728d0B761948e25DD065610E) // myk31.eth
            .call{value: address(this).balance}("");
        if (!success) revert();
    }

    function uri(uint256) public pure override returns (string memory) {
        return "ipfs://QmahErFFT4vXTSBiesCULvqKthVRY4Di5zok8wcWxmHzZh";
    }
}
