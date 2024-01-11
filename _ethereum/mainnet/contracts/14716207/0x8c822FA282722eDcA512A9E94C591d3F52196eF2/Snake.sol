// SPDX-License-Identifier: MIT

// // // // // // // // // // // // // // // // // // // // // // // // // // // // //
//                              ,--.                          ,--.                  //     
//        .--.--.            ,--.'|     ,---,            ,--/  /|      ,---,.       //     
//       /  /    '.      ,--,:  : |    '  .' \        ,---,': / '    ,'  .' |       //      
//      |  :  /`. /   ,`--.'`|  ' :   /  ;    '.      :   : '/ /   ,---.'   |       //      
//      ;  |  |--`    |   :  :  | |  :  :       \     |   '   ,    |   |   .'       //      
//      |  :  ;_      :   |   \ | :  :  |   /\   \    '   |  /     :   :  |-,       //      
//       \  \    `.   |   : '  '; |  |  :  ' ;.   :   |   ;  ;     :   |  ;/|       //      
//        `----.   \  '   ' ;.    ;  |  |  ;/  \   \  :   '   \    |   :   .'       //      
//        __ \  \  |  |   | | \   |  '  :  | \  \ ,'  |   |    '   |   |  |-,       //      
//       /  /`--'  /  '   : |  ; .'  |  |  '  '--'    '   : |.  \  '   :  ;/|       //      
//      '--'.     /   |   | '`--'    |  :  :          |   | '_\.'  |   |    |       //      
//        `--'---'    '   : |        |  | ,'          '   : |      |   :   .'       //      
//                    ;   |.'        `--''            ;   |,'      |   | ,'         //     
//                    '---'                           '---'        `----'           //
// // // // // // // // // // // // // // // // // // // // // // // // // // // // //                                         

pragma solidity 0.8.7;



import "./ERC721.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SnakeLib.sol";
import "./ICalculator.sol";

contract Snake is ERC721, ERC2981, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private tokenSupply;
    
    uint public price = 0.04 ether;

    uint public maxSupply = 10_000;

    string public frontEnd = "TBD";

    ICalculator public calculator = ICalculator(0xC3B88A12D8Cda6b9802C30be4bb18BDd1828b317);

    uint public CalcOwnerMultiplier; 


    mapping(uint => SnakeLib.ColorScheme) internal colorIdToScheme;
    
    mapping(uint => uint) internal idToSchemeIndex;


    

    
    event TokenMint(address purchaser, uint mints);


    constructor() ERC721("Snake", "SNAKE") {
        _setDefaultRoyalty(address(this), 250);
        setDiscount(80); 
        
        colorIdToScheme[1] = SnakeLib.ColorScheme(
            "a612de",
            "a612de",
            "a612de",
            "a612de",
            "a612de",
            "EBDEF0",
            "ffe599",
            "27AE60",
            "FF5D3B"
            );
        colorIdToScheme[2] = SnakeLib.ColorScheme(
            "227c9d",
            "227c9d",
            "227c9d",
            "227c9d",
            "227c9d",
            "fef9ef",
            "17c3b2",
            "fe6d73",
            "ffcb77"
            );
        colorIdToScheme[3] = SnakeLib.ColorScheme(
            "2c6e49",
            "4c956c",
            "4c956c",
            "4c956c",
            "4c956c",
            "ffc9b9",
            "fefee3",
            "ffc9b9",
            "4c956c"
            );

        colorIdToScheme[4] = SnakeLib.ColorScheme(
            "0b090a",
            "0b090a",
            "0b090a",
            "0b090a",
            "0b090a",
            "ba181b",
            "b1a7a6",
            "ba181b",
            "0b090a"
            );
        

        colorIdToScheme[5] = SnakeLib.ColorScheme(
            "fee440",
            "fee440",
            "f15bb5",
            "f15bb5",
            "fee440",
            "9b5de5",
            "00f5d4",
            "f15bb5",
            "fee440"
            );

    }

    /*
        * Takes an array of numbers between 1-5
        * length of schemeIds is the number of tokens to mint. Max amount is 5
     */

    function buySnake(uint[] memory schemeIds) public payable { 
        uint totalMints = schemeIds.length;
        require(msg.value == getFinalPrice(totalMints, msg.sender), "wrong price");
        require(totalMints <= 5 && totalMints > 0, "incorrect number");
        require(tokenSupply.current() + totalMints <= maxSupply, "exceeds max supply");
        
        for(uint i=0; i<totalMints; i++) {
            require(schemeIds[i] > 0 && schemeIds[i]<=5, "color doesn't exist");
            tokenSupply.increment();
            uint256 newItemId = tokenSupply.current();
            idToSchemeIndex[newItemId] = schemeIds[i];
            _safeMint(msg.sender, newItemId);
        }

        emit TokenMint(msg.sender, totalMints);
    }

    function totalSupply() public view returns(uint) {
        return tokenSupply.current();
    }

    function getFinalPrice(uint amount, address user) public view returns (uint) {
        uint finalPrice = price * amount;
        if(calculator.balanceOf(user) > 0) {
            finalPrice = (finalPrice * CalcOwnerMultiplier) / 100;
        }

        return finalPrice;

    }

    function tokenURI(uint id) public view override returns (string memory) {

        address owner = ownerOf(id);
        require(_exists(id), "does not exist");
        uint schemeIndex = idToSchemeIndex[id];
        SnakeLib.ColorScheme memory scheme = colorIdToScheme[schemeIndex];
        
        SnakeLib.SnakeParams memory snakeParams = SnakeLib.SnakeParams({
            _owner: owner,
            _id: id,
            _schemeIndex: schemeIndex,
            _scheme: scheme,
            _frontEnd: frontEnd
        });

        return SnakeLib.generateTokenURI(snakeParams);



    }
    

    // OWNER FUNCTIONS
    function withdrawFunds() public onlyOwner {
        uint amount = address(this).balance;
        Address.sendValue(payable(owner()), amount);
    }

    function setFrontEnd(string memory _frontEnd) public onlyOwner {
        frontEnd = _frontEnd;
    }


    function setDiscount(uint multiplier) public onlyOwner { 
        require(multiplier < 100);
        CalcOwnerMultiplier = multiplier;
    }



    // REQUIRED OVERRIDES:
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721,ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);

    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }






}