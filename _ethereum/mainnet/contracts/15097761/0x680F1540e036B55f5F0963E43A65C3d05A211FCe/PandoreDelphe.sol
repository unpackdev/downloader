//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";


//*********************************************************************//
// --------------------------- custom error ------------------------- //
//*********************************************************************//
error ITEM_DOES_NOT_EXIST();

contract PandoreDelphi is ERC721, Ownable {


    /// @notice Total Items.
    uint256 public constant totalItems = 404;


    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;


    /**
     * @notice Constructor
     **/
    constructor() ERC721("PandoreDelphi", "DLF") {}

    string public constant baseURL = "https://pandore.mypinata.cloud/ipfs/QmZRJNy6y9UmRWUVa5eEGa2vcKZMGv154t9kYfpGMsPBBb/";
    string[404] public metadataURL = 
       ['1.json', '2.json', '3.json', '4.json', '5.json','6.json','7.json','8.json','9.json',
        '10.json','11.json', '12.json', '13.json', '14.json', '15.json', '16.json', '17.json', '18.json', '19.json', 
        '20.json', '21.json', '22.json', '23.json', '24.json', '25.json', '26.json', '27.json', '28.json', '29.json', 
        '30.json', '31.json', '32.json', '33.json', '34.json', '35.json', '36.json', '37.json', '38.json', '39.json', 
        '40.json', '41.json', '42.json', '43.json', '44.json', '45.json', '46.json', '47.json', '48.json', '49.json', 
        '50.json', '51.json', '52.json', '53.json', '54.json', '55.json', '56.json', '57.json', '58.json', '59.json', 
        '60.json', '61.json', '62.json', '63.json', '64.json', '65.json', '66.json', '67.json', '68.json', '69.json', 
        '70.json', '71.json', '72.json', '73.json', '74.json', '75.json', '76.json', '77.json', '78.json', '79.json', 
        '80.json', '81.json', '82.json', '83.json', '84.json', '85.json', '86.json', '87.json', '88.json', '89.json', 
        '90.json', '91.json', '92.json', '93.json', '94.json', '95.json', '96.json', '97.json', '98.json', '99.json', 
        '100.json', '101.json', '102.json', '103.json', '104.json', '105.json', '106.json', '107.json', '108.json', '109.json', 
        '110.json', '111.json', '112.json', '113.json', '114.json', '115.json', '116.json', '117.json', '118.json', '119.json', 
        '120.json', '121.json', '122.json', '123.json', '124.json', '125.json', '126.json', '127.json', '128.json', '129.json', 
        '130.json', '131.json', '132.json', '133.json', '134.json', '135.json', '136.json', '137.json', '138.json', '139.json', 
        '140.json', '141.json', '142.json', '143.json', '144.json', '145.json', '146.json', '147.json', '148.json', '149.json', 
        '150.json', '151.json', '152.json', '153.json', '154.json', '155.json', '156.json', '157.json', '158.json', '159.json', 
        '160.json', '161.json', '162.json', '163.json', '164.json', '165.json', '166.json', '167.json', '168.json', '169.json', 
        '170.json', '171.json', '172.json', '173.json', '174.json', '175.json', '176.json', '177.json', '178.json', '179.json', 
        '180.json', '181.json', '182.json', '183.json', '184.json', '185.json', '186.json', '187.json', '188.json', '189.json', 
        '190.json', '191.json', '192.json', '193.json', '194.json', '195.json', '196.json', '197.json', '198.json', '199.json', 
        '200.json', '201.json', '202.json', '203.json', '204.json', '205.json', '206.json', '207.json', '208.json', '209.json', 
        '210.json', '211.json', '212.json', '213.json', '214.json', '215.json', '216.json', '217.json', '218.json', '219.json', 
        '220.json', '221.json', '222.json', '223.json', '224.json', '225.json', '226.json', '227.json', '228.json', '229.json', 
        '230.json', '231.json', '232.json', '233.json', '234.json', '235.json', '236.json', '237.json', '238.json', '239.json', 
        '240.json', '241.json', '242.json', '243.json', '244.json', '245.json', '246.json', '247.json', '248.json', '249.json', 
        '250.json', '251.json', '252.json', '253.json', '254.json', '255.json', '256.json', '257.json', '258.json', '259.json', 
        '260.json', '261.json', '262.json', '263.json', '264.json', '265.json', '266.json', '267.json', '268.json', '269.json', 
        '270.json', '271.json', '272.json', '273.json', '274.json', '275.json', '276.json', '277.json', '278.json', '279.json', 
        '280.json', '281.json', '282.json', '283.json', '284.json', '285.json', '286.json', '287.json', '288.json', '289.json', 
        '290.json', '291.json', '292.json', '293.json', '294.json', '295.json', '296.json', '297.json', '298.json', '299.json', 
        '300.json', '301.json', '302.json', '303.json', '304.json', '305.json', '306.json', '307.json', '308.json', '309.json', 
        '310.json', '311.json', '312.json', '313.json', '314.json', '315.json', '316.json', '317.json', '318.json', '319.json', 
        '320.json', '321.json', '322.json', '323.json', '324.json', '325.json', '326.json', '327.json', '328.json', '329.json', 
        '330.json', '331.json', '332.json', '333.json', '334.json', '335.json', '336.json', '337.json', '338.json', '339.json', 
        '340.json', '341.json', '342.json', '343.json', '344.json', '345.json', '346.json', '347.json', '348.json', '349.json', 
        '350.json', '351.json', '352.json', '353.json', '354.json', '355.json', '356.json', '357.json', '358.json', '359.json', 
        '360.json', '361.json', '362.json', '363.json', '364.json', '365.json', '366.json', '367.json', '368.json', '369.json', 
        '370.json', '371.json', '372.json', '373.json', '374.json', '375.json', '376.json', '377.json', '378.json', '379.json', 
        '380.json', '381.json', '382.json', '383.json', '384.json', '385.json', '386.json', '387.json', '388.json', '389.json', 
        '390.json', '391.json', '392.json', '393.json', '394.json', '395.json', '396.json', '397.json', '398.json', '399.json', 
        '400.json', '401.json', '402.json', '403.json', '404.json'];
    
    function mintItem() external {

        _tokenIds.increment();
        uint id = _tokenIds.current();

        if (id > totalItems) {
           revert ITEM_DOES_NOT_EXIST();
        }

        _mint(msg.sender, id);
    }

    /*
     * @notice returns the tokenURI of the nft
     * @param _tokenId token id
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) {
            revert ITEM_DOES_NOT_EXIST();
        }
        return string(abi.encodePacked(baseURL, metadataURL[_tokenId-1]));
    }
}