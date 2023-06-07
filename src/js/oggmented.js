import Module from './oggmented-wasm.js';
// import silence from './silence.ogg';
export class OggmentedAudioContext extends(window.AudioContext || window.webkitAudioContext) {
  // need the setPrototypeOf due to this issue:
  // https://stackoverflow.com/questions/58471434/problem-extending-native-es6-classes-in-safari
  constructor(options) {
    super(options);
    Object.setPrototypeOf(this, OggmentedAudioContext.prototype);
  }
  // nativeVorbisLevel() {
  //   return new Promise(resolve => {
  //     // Let's memoize this in e.g. this.vorbisLevel
  //     fetch(silence).then(response => response.arrayBuffer()).then(buffer => super.decodeAudioData(buffer, decodedBuffer => resolve(decodedBuffer.length === 1 ? 'gecko' : 'blink'), error => resolve('webkit')));
  //   });
  // }
  decodeAudioData(buffer, successCallback, errorCallback) {
    /** @type {ConstructorParameters<PromiseConstructor>[0]} */
    const decode = (resolve, reject) => {
      Module().then(oggmented => {
        try {
          oggmented.decodeOggData(buffer, resolve);
        } catch (error) {
          const ab = super.decodeAudioData(buffer, resolve, reject);
          if (ab instanceof Promise) ab.then(resolve, reject);
        }
      });
    };
    if (successCallback) {
      decode(successCallback, errorCallback);
    } else {
      return new Promise(decode);
    }
  }
  // decodeAudioDataSync(buffer) {
  //   return oggmented.decodeOggData(buffer);
  // }
}
export default OggmentedAudioContext;