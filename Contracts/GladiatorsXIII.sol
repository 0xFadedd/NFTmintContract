// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../ERC721Z.sol";

contract GladiatorsXIII is ERC721Z{


/*

need to include onlyOwner standard functions and context libraries from OZ

need to incorperate the key (possibly throught the use of an svg) on the front end to authorise the mint funtion,
so that it cannot be called from the contract itself, and the traits be chosen


*/


    /*so we start with 8192 gladiators, every 2 days the gladiators "1v1" and the loser is burned
the winner will receive a random trait upgrade, it doesn't serve any purpose other than looking cooler atm, although there is potential maybe for us to reward winners with maxed out traits? idk yet
so 3 tiers for each traits, say a bronze helmet, silver, gold

off chain randomisation
on chain metadata storage
possible on chain art storage
auto fight function - win = upgrade / lose = burn
fight function based on time and selected token id would be based on algorim which would select one it knew it hadnt played before to save gas 
this instead of doing a require check
*/
    address _owner;
    uint256 public MaxSupply;
    uint256 public _mintPrice;
    uint256 public maxAmountPerWallet;
    uint256 _dnaModulus = 10 ** 7;
    uint256 _fightMod = 10 ** 2;

    constructor () ERC721Z("Gladiator XIII", "GX") {
        transferOwnership(_msgSender());
        MaxSupply = 8192;
        _mintPrice = 0.03 ether;
        maxAmountPerWallet = 1;
    }

    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event Fight(uint256 indexed FightNumber, uint256 indexed FightTime);

    mapping(uint256 => uint256) public dna;
    mapping(bool => uint256) public alive; // dead = false | alive = true

    modifier callerIsUser () {
        require(msg.sender == tx.origin, "Function caller is not the user");
        _;
    }

    //// OZ Ownerable logic
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // modifier that calls function saves gas
    function _onlyOwner() internal virtual {
        require(owner() == _msgSender(), "Function caller is not the owner");
    }
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
     
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    //converts traits to single dna string
    function _createDNA(uint256[6] memory _traits, uint256 tokenId_) public {
        uint256 DNA;
        for(uint256 i = 0; i < 6; i++) {
            DNA += uint256(_traits[i] * (16 ** ((6 - i) * 8 + 8)));
        }
        dna[tokenId_] = DNA;
    }

    //gets the next available unminted tokenID
    function _getTokenId() internal virtual returns(uint256) {
        return totalSupply + 1;
    }

    /**public mint function
    *
    * Function takes in an array of traits, the tokenID and a secret key
    * This function is external, payable, and can only be called by an EOA and not a contract.
    * standard checks are then carried out ensure that it is possible for that tokenID to be minted
    * The function then mints the next available token to the fucntion caller
    * The function then creates a dna string for that token ID
    *
    **/
    function createGladiator(uint256[6] memory _traits) external payable callerIsUser {
        require(totalSupply < 8192, "Max Supply reached!");
        require(maxAmountPerWallet == 1);
        require(msg.value = _mintPrice);

        _createDNA(_traits, _getTokenId());
        _mint(msg.sender, _getTokenId());
    }

    //public view function to retrieve the array of attributes for a given tokenID
    function getDNA(uint256 tokenId_) public view returns(uint32[6]) {
        uint32[6] memory _dnas = _decodeDNA(dna[tokenId_]);
        return _dnas;
    }
    
    //internal pure function which converts the uint256 dna string into an uint32 array of length 6
    function _decodeDNA(uint256 dna_) internal pure {
        bytes32 _dna = bytes32(dna_);
        uint32[6] memory _dnas;
        for(uint256 i = 0; i < 6; i++) {
            _dnas[5 - i] = uint32(bytes4(_dna << (32 * (5 - i)))); //using 6 because index 6 is 7th item in array
        }
    }

    // functions to select which trait to pick based on the dna

    //trait = _dna

    /*
    *
    ***** These function will: *****
    *
    * Function _renderTraits() will take a trait category trait id and a bool 
    to render the trait based on the element of the dna array 
    * Function _renderAttributes will use a for loop to loop through the _renderTraits() function to get
    a text version of the properties of the traits
    **/

    function _getHelmet(uint32 _dna) internal view {
        GladiatorHelmet.getHelmet(_dna);
    }
    function _getEyes(uint32 _dna) internal view {
        GladiatorEyes.getEyes(_dna);
    }
    function _getBeard(uint32 _dna) internal view {
        GladiatorBeard.getBeard(_dna);
    }
    function _getBody(uint32 _dna) internal view {
        GladiatorBody.getBody(_dna);
    }
    function _getRobes(uint32 _dna) internal view {
        GladiatorRobes.getRobes(_dna);
    }
    function _getWeapon(uint32 _dna) internal view {
        GladiatorWeapon.getWeapon(_dna);
    }
    function _getBackground(uint32 _dna) internal view {
        GladiatorBackground.getBackground(_dna);
    }

    function getAttributes(uint32[7] memory _dna) public view {

    }

    function renderSVG(uint256 tokenId_) public virtual {
        
    }

    /*
    *
    * These functions determine whether metadata is shown
    *
    **/
    function isMetaDataShown(uint32 traitCategory_, uint32 traitId_) public view returns(bool){
        if (
            traitCategory_ == 0 ||
            traitCategory_ == 1 ||
            traitCategory_ == 2 ||
            traitCategory_ == 3 ||
            traitCategory_ == 4 ||
            traitCategory_ == 5
            ) 
        { return true; }
        else { return false; }
    }


    //to string function
    function toString(uint256 value_) public pure returns (string memory) {
        if (value_ == 0) { return "0"; }
        uint256 _iterate = value_; uint256 _digits;
        while (_iterate != 0) { _digits++; _iterate /= 10; } // get digits in value_
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) { _digits--; _buffer[_digits] = bytes1(uint8(48 + uint256(value_ % 10 ))); value_ /= 10; } // create bytes of value_
        return string(_buffer); // return string converted bytes of value_
    }

    //base64 encoder
    // Base64 Encoder
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    function encodeBase64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
        string memory table = TABLE;
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen + 32);
        assembly {
            mstore(result, encodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)
            for {} lt(dataPtr, endPtr) {} {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload( add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }
        return result;
    }

    /** 
    *
    *
    *
    *               Image rendering functions
    *
    *
    *
    */

    string public constant _svgHeader;
    string public constant _svgFooter;

    function _imageWrapper(bool first_) public pure returns (string memory) {
        string memory _wrapper = "<image x='0' y='0' width='64' height='64' image-rendering='pixelated' preserveAspectRatio='xMidYMid' xlink:href='data:image/png;base64,";
        if (!first_) _wrapper = string(abi.encodePacked("'/>", _wrapper));
        return _wrapper;
    }

    function _renderGladiatorTraits(uint32 traitCategory_, uint32 traitId_, bool last_) public view returns (string memory) {
        string memory _trait = string(abi.encodePacked('{"trait_type":"', 'Gladiator Trait', '","value":"'));
        
        if (traitCategory_ == 0) {
            _trait = string(abi.encodePacked(_trait, GladiatorHelmet.getHelmet(traitId_)));
        }
        if (traitCategory_ == 1) {
            _trait = string(abi.encodePacked(_trait, GladiatorEyes.getEyes(traitId_)));
        }
        if (traitCategory_ == 2) {
            _trait = string(abi.encodePacked(_trait, GladiatorBeard.getBeard(traitId_)));
        }
        if (traitCategory_ == 3) {
            _trait = string(abi.encodePacked(_trait, GladiatorRobes.getRobes(traitId_)));
        }
        if (traitCategory_ == 4) {
            _trait = string(abi.encodePacked(_trait, GladiatorWeapon.getWeapon(traitId_)));
        }
        if (traitCategory_ == 5) {
            _trait = string(abi.encodePacked(_trait, GladiatorBody.getBody(traitId_)));
        }
        if (traitCategory_ == 6) {
            _trait = string(abi.encodePacked(_trait, GladiatorBackground.getBackground(traitId_)));
        }

        string memory _footer = last_ ? '"}' : '"},';

        _trait = string(abi.encodePacked(
            _trait,
            _footer
        )); 

        return _trait;
    }

    function _renderGladiatorSVG(uint32[7] memory _dnas) public view returns (string memory) {
        string memory _svg = string(abi.encodePacked(
            _svgHeader,
            _imageWrapper(true),
            GladiatorBackground.getBackground(_dnas[0])[1],
            _imageWrapper(false),
            GladiatorBody.getBody(_dnas[1])[1],
            _imageWrapper(false),
            GladiatorHelmet.getArmour(_dnas[2])[1]
        ));

        _svg = string(abi.encodePacked(
            _svg,
            _imageWrapper(false),
            GladiatorBeard.getHelmet(_dnas[3])[1],
            _imageWrapper(false),
            GladiatorEyes.getArms(_dnas[4])[1],
            _imageWrapper(false)
        ));

        _svg = string(abi.encodePacked(
            _svg,
            GladiatorWeapon.getWeapon(_dnas[6])[1],
            _svgFooter
        ));

        return _svg;
    }


    function killGladiators(uint256[] memory tokenIds_) internal virtual {
        for(uint256 i = 0; i < tokenIds_.length; i++) {
            alive[tokenIds_[i]] = false;
        }
    }

    uint256 public startingSupply = 8192;
    uint256 public stepAmount = 1 / 2;
    uint256 public stepNumber = 1;

    /*

    GLADIATOR FIGHT

    //require functions
    require pause isnt on
    

    //logic
    finds how many are left
    uses the front end to get an array of the ids OR uses the keccak hash to get an array of random numbers
    once the array reaches the length of 50% of the starting supply, then it changes all of the alive mappings for the token ids in the array to false showing they are dead
    for all those that are left it updates part of their dna sequence on the front end and saves it to their dna

    //notes
    doing randomisation on the front end improves security as there is a lot on the line and it makes it more cost efficient for users and team. only downside is the trustlessness is reduced.

    **/


    //need to include what will happen if not all 8192 NFTs are minted

    function gladiatorFight(
        uint256[] memory tokenIdsDead_,
        uint256[] memory tokenIdsAlive_,
        uint32[] memory newDNAtraits
    ) external onlyOwner {
        //for token ids that have gladiator.alive or alive[tokenId_] == true | set 50% of tokens to dead
        uint256 amountLeft = startingSupply * stepAmount * stepNumber;
        killGladiators(tokenIdsDead_[]);
        for(uint256 i = 0; i < amountLeft; i++) {
            //random number to determine which part of dna it updates from off chain
            //then update that piece of dna to a random number
            if (alive[i] = true) {
                _createDNA(newDNAtraits[i], tokenIdsAlive_[i]);
            }
        }
        emit Fight(stepNumber, block.timestamp); 
        stepNumber++;
               
    }

    function setKey(uint256 _OwnerKey) external onlyOwner {
        uint256 key_ = _OwnerKey;
    }

    function renderAttributes() public virtual {

    }

    function renderSVG() public virtual {

    }

    string description = "GladiatorsXIII is a lottery style game in which your NFTs will fight to the death until only one remains to claim the Grand Prize. It could be you!";

    function getDescription() public virtual returns(string) {
        return description;
    }

    //token uri stuff
    /*
    *
    * token uri function (everything is joined by string(abi.encodePacked()))
    *
    * metadata;
    * metadata = token id
    * metadata = metadata + svg
    * metadata = metadata + attributes
    * metadata = metadata + meta header ('data:application/json;base64,')
    * encodebase64(bytes(metadata))
    *
    **/

    string _metaHeader = 'data:application/json;base64,';

    function tokenURI(uint256 tokenId_) public view returns (string memory) {
        return _tokenURI(tokenId_);
    }
    
    function _tokenURI(uint256 tokenId_) internal view returns (string memory) {
        string memory _metadata;

        _metadata = string(abi.encodePacked(
            '{"name":"',
            tokenId_,
            '", "description":"',
            getDescription(),
            '", "image": "data:image/svg+xml;base64,'
        ));

        _metadata = string(abi.encodePacked(
            _metadata,
            encodeBase64(bytes(renderSVG(tokenId_))),
            '","attributes": ['
        ));

        _metadata = string(abi.encodePacked(
            _metadata,
            renderAttributes(tokenId_),
            ']}'
        ));

        return string(abi.encodePacked(
            _metaHeader,
            encodeBase64(_metadata)
        ));
    }
}