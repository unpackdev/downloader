//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author tanujd.eth tmtlab.eth
/// @title ThePeepsProject Free Mint ERC1155 Smart Contract
/// @notice Join ThePeepsProject

// Imports
import "./ERC1155.sol";
import "./Ownable.sol";
import "./Counters.sol";

// Contract
contract TPPFreeMint is ERC1155, Ownable {
    using Counters for Counters.Counter;

    /// @notice defines the contract states
    enum Status {
        Paused,
        Mint
    }
    Status public status;

    uint256 public maxVolume;
    uint256 public seasonStart;
    uint256 public seasonEnd;
    string public name;
    string public symbol;

    // Track the addresses and how many they minted
    mapping(address => uint256) addressMintedCount;
    
    // Token URIs
    mapping(uint256 => string) tokenURI;

    /// @dev tracking the season & volume
    Counters.Counter seasonCounter;
    Counters.Counter volumeCounter;

    constructor(string memory _name, string memory _symbol, string memory _uri, uint256 _start, uint256 _end, uint256 _maxVolume) ERC1155("") {
        name = _name;
        symbol = _symbol;
        maxVolume = _maxVolume;
        changeSeason(_uri, _start, _end);
        mint(msg.sender);
        status = Status.Paused;
    }

    // Contract Functions
    /// @notice Update the contract state
    function setState(Status _state) public onlyOwner {
        status = _state;
    }

    /// @notice Displays season and volume numbers.
    function viewStats() public view onlyOwner returns (uint256 season, uint256 volume) {
        season = seasonCounter.current();
        volume = volumeCounter.current();
    }

    /// @notice Updated the number of tickets available for a season
    function setSeasonVolume(uint256 _tickets) public onlyOwner {
        maxVolume = _tickets;
    }

    /// @notice set the start and end dates for the season
    function setSeasonDates(uint256 _start, uint256 _end) public onlyOwner {
        seasonStart = _start;
        seasonEnd = _end;
    }

    /// @notice set the start date for the season
    function setSeasonStart(uint256 _start) public onlyOwner {
        seasonStart = _start;
    }

    /// @notice set the end date for the season
    function setSeasonEnd(uint256 _end) public onlyOwner {
        seasonEnd = _end;
    }

    /// @notice set the uri for the tokens
    function setUri(uint256 _id, string memory _uri) external onlyOwner {
        tokenURI[_id] = _uri;
    }

    /// @dev overrides the uri funciton to set custom images
    function uri(uint256 _id) public view virtual override returns(string memory) {
        return tokenURI[_id];
    }

    /// @notice Updates contract to next season and adds new season's uri
    function changeSeason(string memory _uri, uint256 _start, uint256 _end) public onlyOwner {
        require(_start >= block.timestamp, "Start date should be in the future.");
        require(block.timestamp <= _end && _start < _end, "End Date should be in the future and more than the start date.");
        seasonStart = _start;
        seasonEnd = _end;
        seasonCounter.increment();
        volumeCounter.reset();
        uint256 season = seasonCounter.current();
        tokenURI[season] = _uri;
    }

    // Mint
    /// @notice  Checks if the  mint parameters are met and then Mints.
    function mintTicket() public payable {
        require(status == Status.Mint, "The contract is not currently minting.");
        require(seasonStart <= block.timestamp, "Minting has not started yet.");
        require(block.timestamp <= seasonEnd, "Minting has ended.");
        require(addressMintedCount[msg.sender] < seasonCounter.current(), "Exceeded mint limit.");
        require(volumeCounter.current() + 1 <= maxVolume, "Exceeded the maximum available volume.");

        mint(msg.sender);
    }

    /// @notice Function that mints the NFT
    function mint(address _address) internal {
        _mint(_address, seasonCounter.current(), 1, "");
        addressMintedCount[_address] = seasonCounter.current();
        volumeCounter.increment();
    }

    /// @notice Failsafe if someone mistakingly sends money to the contract, so it can be returned
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }

}