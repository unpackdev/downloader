// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


import "./ERC1155Burnable.sol";
import "./IERC721.sol";

contract MetaSharksComic is ERC1155Burnable {
    uint256[] public maxSupplies = [100,300,600];
    uint256[] public minted = [0,0,0];
    uint256[] public burnt = [0,0,0];
    uint256[] public cost = [.1 ether, .07 ether, .04 ether];
    string public name = "MetaSharks Comic #1";
    string public symbol = "MSC1";
    bool public sale = false;

    address private owner;
	address private admin = 0x8DFdD0FF4661abd44B06b1204C6334eACc8575af;
    address private sharkAddress = 0x30A51024cEf9E1C16E0d9F0Dd4ACC9064D01f8da;

    constructor() ERC1155("https://metasharks.mypinata.cloud/ipfs/QmZdTHvAxNvxgMXbppVzsUg7k4GbdrfGa69qNXqcLyxkis/{id}.json") 
    {
        owner = msg.sender;
    }

    modifier onlyTeam {
        require(msg.sender == owner || msg.sender == admin, "Not team" );
        _;
    }
    modifier onlySharkHolder {
        require(IERC721(sharkAddress).balanceOf(msg.sender) > 0, "Must be a shark holder");
        _;
    }

    function setURI(string memory newuri) public onlyTeam {
        _setURI(newuri);
    }

    function mint(uint256 id, uint256 amount) public payable onlySharkHolder{
        require(sale, "Sale");
        require(id < maxSupplies.length && id >= 0, "ID does not exist");
        require(amount < 11, "Too many");
        require(minted[id] + amount <= maxSupplies[id], "Max supply");
        require(msg.value == amount * cost[id], "ETH value");
        _mint(msg.sender, id, amount, "");
        minted[id] += amount;
    }

    function multiMint(uint256[] memory ids, uint256[] memory amounts) public payable onlySharkHolder{
        require(sale, "Sale");
        require(ids.length == amounts.length, "List length");
        require(ids.length < 4, "Too many");
        // calculate costs
        uint256 totalCost = 0; 
        for(uint256 i; i < ids.length; i++){
            require(amounts[i] < 11, "Too many");
            require(ids[i] < 4 && ids[i] >= 0);
            totalCost += cost[ids[i]] * amounts[i];
    	}

        require(msg.value == totalCost, "ETH value");
        delete totalCost;
        for(uint256 i; i < ids.length; i++){
            require(minted[ids[i]] + amounts[i] <= maxSupplies[ids[i]], "Max supply");
            _mint(msg.sender, ids[i], amounts[i], "");
            minted[ids[i]] += amounts[i];
    	}
    }

    function gift(uint256 id, uint256 amount, address recipient) public onlyTeam {
        require(id < maxSupplies.length && id >= 0, "ID does not exist"); 
        require(minted[id] + amount <= maxSupplies[id], "Max supply"); 
        _mint(recipient, id, amount, "");
        minted[id] += amount;
    }

    function burn(address account, uint256 id, uint256 value) public virtual override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _burn(account, id, value);
        require(id < burnt.length, "ID does not exist");
        burnt[id] += value;
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);

        for(uint256 i; i < ids.length; i++){
            require(ids[i] < burnt.length, "ID does not exist");
            burnt[ids[i]] += values[i];
        }
    }

    function toggleSale() public {
        sale = !sale;
    }

    function totalMints() public view returns(uint256[] memory){
        return minted;
    }

    function totalBurns() public view returns(uint256[] memory){
        return burnt;
    }

    function withdraw()  public onlyTeam {
        payable(admin).transfer(address(this).balance * 15 / 100);
        payable(owner).transfer(address(this).balance);
    }

    function setSharkAddress(address _sharkAddress) public onlyTeam {
        sharkAddress = _sharkAddress;
    }

}