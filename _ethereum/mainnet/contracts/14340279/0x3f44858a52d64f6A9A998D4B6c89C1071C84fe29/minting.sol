import "./VerifySignature.sol";
import "./Ownable.sol";

pragma solidity ^0.8.0;

interface Minimalmint {
    function mintafterverification(
        uint256 value1,
        uint256 value2,
        uint256 colorpointer,
        uint256 tokenid,
        string memory rtimetamp
    ) external;
}

contract Minting is VerifySignature, Ownable {
    Minimalmint minter;
    address internal dataprovider;
    uint256 public nonce;
    uint256 public constant mint_price = 150000000000000000 wei;

    address public currentcurator;
    address public terra0multisig;
    mapping(address => curator) public curators;

    uint256 public maxnonce = 2001;
    uint256[2] public temprange = [19000, 23000];
    uint256[2] public moistrange = [70000, 80000];

    uint256 public timelimit = 2200;
    uint256 public artistmintcounter = 15;

    struct curator {
        uint256 percentage;
        uint256 colorandlocationpointer;
        bool curatorwhitelist;
        uint256 curatorshares;
    }

    constructor(
        address _dataprovider,
        address _terra0multisig,
        address _erc721
    ) {
        dataprovider = _dataprovider;
        terra0multisig = _terra0multisig;
        nonce = 0;
        maxnonce = 1601;
        timelimit = 2200;
        minter = Minimalmint(_erc721);

    }

    function checkrange(
        uint256 value,
        uint256 downrange,
        uint256 upperrange
    ) public pure returns (bool pass) {
        bool down = value >= downrange;
        bool up = value <= upperrange;
        return (bool(down && up));
    }

    function artistmint(
        uint256 value1,
        uint256 value2,
        uint256 _nonce,
        string memory htimestamp,
        uint256 colorandlocationpointer
    ) external onlyOwner {
        require(_nonce < maxnonce, "Max number of tokens minted");
        require(currentcurator != address(0), "No curator set");

        require(
            checkrange(value1, moistrange[0], moistrange[1]) == true,
            "Moisture range out of bounds"
        );
        require(
            checkrange(value2, temprange[0], temprange[1]) == true,
            "Temperature range out of bounds"
        );
        require(artistmintcounter > 0);
        artistmintcounter -= 1;
        minter.mintafterverification(
            value1,
            value2,
            colorandlocationpointer,
            _nonce,
            htimestamp
        );
        nonce = _nonce;
    }

    function mintwithSignedData(
        address signer,
        uint256 value1,
        uint256 value2,
        uint256 _nonce,
        uint256 timestamp,
        string memory htimestamp,
        bytes memory signature
    ) external payable {
        require(
            verify(
                signer,
                value1,
                value2,
                _nonce,
                timestamp,
                htimestamp,
                signature
            ) == true,
            "Wrong signature"
        );
        require(signer == dataprovider, "Signer is not dataprovider");
        require(_nonce > nonce, "Datapacket already minted");
        uint256 latest_date = block.timestamp - timelimit;
        require(timestamp > latest_date, "Datapacket too old");
        require(msg.value >= mint_price, "Insufficient payment");
        require(currentcurator != address(0), "No curator set");
        require(_nonce < maxnonce, "Max number tokens minted");
        require(
            checkrange(value1, moistrange[0], moistrange[1]) == true,
            "Moisture range out of bounds"
        );
        require(
            checkrange(value2, temprange[0], temprange[1]) == true,
            "Temperature range out of bounds"
        );
        nonce = _nonce;
        minter.mintafterverification(
            value1,
            value2,
            curators[currentcurator].colorandlocationpointer,
            _nonce,
            htimestamp
        );
        curators[currentcurator].curatorshares =
            curators[currentcurator].curatorshares +
            (mint_price / curators[currentcurator].percentage);
        uint256 terra0value = mint_price -
            (mint_price / curators[currentcurator].percentage);
        (bool sent, ) = payable(terra0multisig).call{value: terra0value}("");
        require(sent, "Transfer failed.");
    }

    function setcurator(
        address _curator,
        uint256 percentage,
        uint256 colorandlocationpointer
    ) external onlyOwner {
        currentcurator = _curator;
        curators[currentcurator].curatorwhitelist = false;
        curators[currentcurator]
            .colorandlocationpointer = colorandlocationpointer;
        curators[currentcurator].percentage = percentage;
    }

    function whitelistwithdrawcurator(address _curator) external onlyOwner {
        curators[_curator].curatorwhitelist = true;
    }

    function withdraw() external {
        require(
            curators[msg.sender].curatorwhitelist == true,
            "Exhibition still running"
        );
        uint256 share = curators[msg.sender].curatorshares;
        curators[msg.sender].curatorshares = 0;
        (bool sent, ) = msg.sender.call{value: share}("");
        require(sent, "Transfer failed.");
    }

    function changetimelimit(uint256 newtimelimit) external onlyOwner {
        timelimit = newtimelimit;
    }

    function changevaluerange(
        uint256 temprange0,
        uint256 temprange1,
        uint256 moistrange0,
        uint256 moistrange1
    ) public onlyOwner {
        temprange[0] = temprange0;
        temprange[1] = temprange1;
        moistrange[0] = moistrange0;
        moistrange[1] = moistrange1;
    }
}
