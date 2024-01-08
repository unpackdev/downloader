// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.7 <0.9.0;

import "./ERC721.sol";

// IAmTheChad is a singleton NFT for the person who's the most willing to transact
// even when gas prices are high. It can be used as a standard NFT, but has the
// caveat that anyone can reown it in periods when the BASEFEE is higher than
// the last time it was reowned. The NFT is - after all - made for Chad!
//
// To support the contract creator, each reown entails a royalty that needs to
// be paid to the original author. After all, a true Chad support art creators!
contract IAmTheChad is ERC721 {
    // author is the creator of the contract and the entity that receives any
    // reown royalties. The author can also lower (never increase) the reown
    // royalty and can relinquish the contract to a new address.
    address public author;

    // reownBasefee is the basefee that needs to be exceeded in order to reown
    // the NFT from its previous owner.
    uint public reownBasefee;
    
    // reownRoyalty is the amount of Wei that needs to be paid to the contract
    // author as a royalty to reown.
    uint public reownRoyalty;
    
    // hallOfFame is the list of accounts that have reowned the NFT. These are
    // the true Chads of Ethereum.
    address[] public hallOfFame;
    
    // The constructor creates a single token for the IAmChad NFT collection,
    // owned by the deployer, reownable at the current BASEFEE.
    constructor() ERC721("I Am The Chad", "IAMTHECHAD") {
        author       = msg.sender;
        reownBasefee = block.basefee;
        reownRoyalty = 1 ether;
        
        _mint(msg.sender, 1); // Singleton token with ID=1
        hallOfFame.push(msg.sender);
    }
    
    // reown attempts to take the NFT away from its current owner and give it
    // to the caller - if and only if - the current basefee is higher than the
    // previous reown level.
    function reown() public payable {
        // Make sure the basefee is high enough for the reown to be permitted
        require(block.basefee > reownBasefee, "Basefee not enough high to reown");
        
        // Make sure the royalty paid is high enough for the reown to be permitted
        require(msg.value >= reownRoyalty, "Royalty not enough to reown");

        reownBasefee = block.basefee;
        
        // Burn and recreate the NFT to ensure no internal state is leaked from
        // the previous owner (singleton token with ID=1)
        _burn(1);
        
        _mint(msg.sender, 1);
        hallOfFame.push(msg.sender);
    }
    
    // reprice can be used by the contract author to lower the royalties paid
    // upon reown. Royalties can never be increased.
    function reprice(uint royalty) public {
        require(msg.sender == author);    // Only the contract author can reprice the royalty
        require(royalty < reownRoyalty); // The royalty may only be decreased, never increased
        
        reownRoyalty = royalty;
    }
    
    // reauthor can be used by the contract author to transfer ownership of the
    // contract (not the NFT!) to a new address.
    function reauthor(address newAuthor) public {
        require(msg.sender == author); // Only the contrct author can relinquish the royalty address
        
        author = newAuthor;
    }
    
    // withdraw can be used by the contract author to withdraw any accumulated royalties.
    function withdraw() public {
        require(msg.sender == author); // Only the contract author can withdraw the royalties
        
        payable(author).transfer(address(this).balance);
    }
    
    // tokenURI generates an SVG data URI to display as a vanity image for the NFT.
    function tokenURI(uint256) public view override returns (string memory) {
        string memory chads = "";
        for (uint i=0; i<hallOfFame.length; i++) {
            chads = string(abi.encodePacked(itoa(i+1), ". ", chads, atoa(hallOfFame[i]), "%5Cn"));
        }
        return string(abi.encodePacked(metaPrefix, chads, metaInfix, imgPrefix, itoa(reownBasefee / 1_000_000_000), imgSuffix, metaSuffix));
    }
    
    string metaPrefix = "data:application/json;charset=UTF-8,%7B%22name%22%3A %22I'm The Chad%22,%22description%22%3A %22I'm The Chad is a singleton NFT for the person who's the most willing to transact even when gas prices are high. It can be used as a standard NFT, but anyone can reown it when the BASEFEE is higher than the last time it was reowned %28see%20%60reownBasefee%60%29. The NFT is - after all - made for Chad!%5Cn%5CnTo support the contract creator, each reown entails a royalty that needs to be paid %28see%20%60reownRoyalty%60%29. After all, a true Chad supports art!%5Cn%5CnHall of Fame%3A%5Cn";
    string metaInfix  = "%22,%22image%22%3A %22";
    string metaSuffix = "%22%7D";
    string imgPrefix  = "data:image/svg+xml;charset=UTF-8,%3csvg xmlns='http://www.w3.org/2000/svg' width='512' height='256'%3e%3cdefs%3e%3clinearGradient id='gf' y2='256' gradientUnits='userSpaceOnUse'%3e%3cstop offset='0' stop-color='%23ffab2e' /%3e%3cstop offset='0.14' stop-color='%23fa8034' /%3e stop offset='0.29' stop-color='%23eb5541' /%3e%3cstop offset='0.43' stop-color='%23d3284d' /%3e stop offset='0.57' stop-color='%23b20058' /%3e%3cstop offset='0.71' stop-color='%2388005f' /%3e stop offset='0.86' stop-color='%23550061' /%3e%3cstop offset='1' stop-color='%2306005c' /%3e%3c/linearGradient%3e%3c/defs%3e%3crect width='512' height='256' fill='url(%23gf)'/%3e%3ctext x='50%25' y='40%25' text-anchor='middle' font-family='Courier New' font-size='48px' fill='%23efe'%3eI'm The Chad%3c/text%3e%3ctext x='50%25' y='75%25' text-anchor='middle' font-family='Courier New' font-size='32px' fill='%23efe'%3eMinted @";
    string imgSuffix  = " GWei%3c/text%3e%3c/svg%3e";
    
    // itoa converts an int to a string.
    function itoa(uint n) internal pure returns (string memory) {
        if (n == 0) {
            return "0";
        }
        bytes memory reversed = new bytes(100);
        uint len = 0;
        while (n != 0) {
            uint r = n % 10;
            n = n / 10;
            reversed[len++] = bytes1(uint8(48 + r));
        }
        bytes memory buf = new bytes(len);
        for (uint i= 0; i < len; i++) {
            buf[i] = reversed[len - i - 1];
        }
        return string(buf);
    }
    
    // atoa converts an address to a string.
    function atoa(address a) internal pure returns (string memory) {
        bytes memory addr     = abi.encodePacked(a);
        bytes memory alphabet = "0123456789abcdef";

        bytes memory buf = new bytes(2 + addr.length * 2);
        buf[0] = "0";
        buf[1] = "x";
        for (uint i = 0; i < addr.length; i++) {
            buf[2+i*2] = alphabet[uint(uint8(addr[i] >> 4))];
            buf[3+i*2] = alphabet[uint(uint8(addr[i] & 0x0f))];
        }
        return string(buf);
    }
}
