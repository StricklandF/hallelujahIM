#import "WebServer.h"
#import "marisa.h"
#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>
#import <MDCDamerauLevenshtein/MDCDamerauLevenshtein.h>

const NSString *kConnectionName = @"Hallelujah_1_Connection";
IMKServer *server;
IMKCandidates *sharedCandidates;
marisa::Trie trie;
NSDictionary *wordsWithFrequencyAndTranslation;
NSDictionary *substitutions;
NSDictionary *pinyinDict;
NSDictionary *phonexEncoded;
NSUserDefaults *preference;

NSDictionary *deserializeJSON(NSString *path) {
    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath:path];
    [inputStream open];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithStream:inputStream options:nil error:nil];

    [inputStream close];
    return dict;
}

NSDictionary *getWordsWithFrequencyAndTranslation() {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"words_with_frequency_and_translation_and_ipa" ofType:@"json"];
    return deserializeJSON(path);
}

NSDictionary *getPinyinData() {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"cedict" ofType:@"json"];
    return deserializeJSON(path);
}

NSDictionary *getPhonexEncodedWords() {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"phonex_encoded_words" ofType:@"json"];
    return deserializeJSON(path);
}

NSDictionary *getUserDefinedSubstitutions() {
    NSString *path = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/.you_expand_me.json"];
    return deserializeJSON(path);
}

int main(int argc, char *argv[]) {
    NSUInteger dis1 = [@"Central Park" mdc_levenshteinDistanceTo:@"Centarl Prak"];         // => 4
    NSUInteger dis2 = [@"Central Park" mdc_damerauLevenshteinDistanceTo:@"Centarl Prak"];  // => 2
    
    NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
    server = [[IMKServer alloc] initWithName:(NSString *)kConnectionName bundleIdentifier:identifier];

    sharedCandidates = [[IMKCandidates alloc] initWithServer:server panelType:kIMKSingleColumnScrollingCandidatePanel];

    if (!sharedCandidates) {
        NSLog(@"Fatal error: Cannot initialize shared candidate panel with connection %@.", kConnectionName);
        return -1;
    }

    NSString *path = [[NSBundle mainBundle] pathForResource:@"google_227800_words" ofType:@"bin"];
    const char *path2 = [path cStringUsingEncoding:[NSString defaultCStringEncoding]];
    trie.load(path2);

    wordsWithFrequencyAndTranslation = getWordsWithFrequencyAndTranslation();
    substitutions = getUserDefinedSubstitutions();
    pinyinDict = getPinyinData();
    phonexEncoded = getPhonexEncodedWords();

    [[NSBundle mainBundle] loadNibNamed:@"AnnotationWindow" owner:[NSApplication sharedApplication] topLevelObjects:nil];

    [[NSBundle mainBundle] loadNibNamed:@"PreferencesMenu" owner:[NSApplication sharedApplication] topLevelObjects:nil];

    [[WebServer sharedServer] start];

    [[NSApplication sharedApplication] run];
    return 0;
}
