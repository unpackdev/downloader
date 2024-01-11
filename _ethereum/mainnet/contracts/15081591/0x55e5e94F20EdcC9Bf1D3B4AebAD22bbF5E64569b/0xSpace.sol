// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
/*
..........................................................................................
..........................................................................................
....................%%%###********#####%%%#****#%.........................................
..............%%#*+++*****###########*=-::.-=:..::=*%.....................................
...........%#*+++**#####%%%%%%%%%%%*-:::. -::------==+*#%.................................
.........%#*+=+######%@@%#%@@@@@@@=:::. .===+===+===+*******#%............................
........%**+=+##*###@@%*%@@@@@@@@-::-..:.--:-==+**#*#%%%*%%##****#%.......................
........#**+=*#####%@@##@@@@@@@@*:--------===+==++%#*#%%##%%%%###**+*%....................
........%**+=*##*###@@#*@@@@@@@@=-----=+==++++******%%%%%#@@@%%%%###**+*%.................
.........#*++=*######@@##%@@@@@@+====--==+==+######%#%%%##@@@@@%#%@%###*++#%..............
.........%#*++=*##*###%@@##%@@@@#==+=++==+*#%##%%%@@@@%%*@@@@@@@@##@%####*++*%............
...........#*++=+*######%@@%#%@@@*-=+++**#%%%%%%%%@@%%%*%@@@@@@@@@*#@@#####+++*%..........
............%#**+=+*#######%@@%##%*+++*###%%%%%@@%%%##*%@@@@@@@@@@*#@@%#####*=+*#.........
...............#**++++*#######%%@%%#*++####%%%%%%##**%@@@@@@@@@@%##%@@%###*##+=+*#........
.................%#**++++*#########%%@%#**********#@@@@@@@@%%####%@@%####*###+=+**%.......
....................%#**+++++*##########%%%%@@@%%%%%%%%%%%%%%@@@@%%#####*###*==+**#.......
.......................%##**+++++**##############%%%%%%%%%%%%#########*####+==+***%.......
...........................%%#**+++++++***#############################**+==++***%........
................................%%#***++++++++++*****##########*****++==++++***#..........
......................................%%##*****++++++++++++++++++++++++****#%%............
..............................................%%%####**************####%%.................
..........................................................................................
..........................................................................................
..................  ###           #####                             ......................
.................. #   #  #    # #     # #####    ##    ####  ######......................
..................#     #  #  #  #       #    #  #  #  #    # #     ......................
..................#     #   ##    #####  #    # #    # #      ##### ......................
..................#     #   ##         # #####  ###### #      #     ......................
.................. #   #   #  #  #     # #      #    # #    # #     ......................
..................  ###   #    #  #####  #      #    #  ####  ###### .....................
..........................................................................................
..........................................................................................
*/

contract OxSpace is Ownable, ERC721A  {

    string private _baseTokenURI;
    uint256 private _price = 0.3 ether;
    uint256 private _maxSuppply = 256;
    bool private _paused = true;

    // withdraw addresses
    address constant private t1 = 0x8e3c9462d6C83868949Dde9d96A74a0e56C5d35B;
    address constant private t2 = 0xf57c5Aa47136B5af7E95F4C9A9afB65E445BA148;

    constructor(string memory baseURI) ERC721A("0xSpace", "0xSpace")  {
        setBaseURI(baseURI);
    }

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !_paused, "The contract has been paused by owner" );
        require( num <= 5, "You can mint a maximum of 5 planets" );
        require( supply + num <= _maxSuppply, "Exceeds maximum planets supply" );
        require( msg.value >= _price * num, "Not enough Eth to buy" );

        _safeMint(msg.sender, num);
    }

    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        require( newMaxSupply > totalSupply(), "New maximum should be more than total supply" );
        _maxSuppply = newMaxSupply;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function getMaxSupply() public view returns (uint256){
        return _maxSuppply;
    }

    function giveAway(
        address to,
        uint256 amount
    ) external onlyOwner {
        uint256 supply = totalSupply();

        require( supply + amount <= _maxSuppply, "Exceeds maximum planets supply" );

        _safeMint(to, amount);
    }

    function setIsPaused(bool isPaused) public onlyOwner {
        _paused = isPaused;
    }

    function getIsPaused() public view returns(bool) {
        return _paused;
    }

    function withdrawAllInternal() private {
        uint256 balance = address(this).balance;
        uint256 firstPart = balance / 2;
        require(payable(t1).send(firstPart));
        require(payable(t2).send(balance - firstPart));
    }

    function withdrawAll() public payable onlyOwner {
        withdrawAllInternal();
    }
}