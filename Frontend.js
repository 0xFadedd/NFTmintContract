const { default: Web3 } = require("web3");

var _traits = []

function getTraits () {
    for (let i = 0; i < 6; i++) {
        if (i === 0) {
            _traits[i] = (1);
        }
        if (i === 1) {
            _traits[i] = (Math.floor(Math.random() * 2) + 1);
        }
        if (i === 2) {
            _traits[i] = (Math.floor(Math.random() * 7) + 1);
        }
        if (i === 3) {
            _traits[i] = (Math.floor(Math.random() * 7) + 1);
        }
        if (i === 4) {
            _traits[i] = (Math.floor(Math.random() * 7)+ 1)
        }
        if (i === 5) {
            _traits[i] = (Math.floor(Math.random() * /* number of weapon traits */8) + 1);
        }

    }
    return _traits;
}

var MyContract = new Web3.eth.Contract(/*json abi, contract address*/);

const transactionParameters = {
    nonce: '0x00',
    gasPrice: '0x09184e72a000',
    gas: '0x2710',
    to: ethereum.selectedAddress,
    from: '0x0000000000000000000000000000000000000000',
    data: MyContract.methods.CreateGladiator(getTraits()),
    value: '0x83185AC0364000'
}



await ethereum.request({
    method: 'eth.sendTransaction',
    params: [transactionParameters],
});


