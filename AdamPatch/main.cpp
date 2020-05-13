#include <cstdio>
#include <cstdlib>
#include <clocale>

#include <unistd.h>
#include <ncurses.h>

enum PATCH_ERROR {
    NO_ERROR,
    SIZE_MISMATCH,
    HASH_MISMATCH
};

size_t loadFile(const char *filename, char **buf);

PATCH_ERROR patchFile(unsigned char *buf, size_t sz);

void saveFile(const char *filename, const char *buf, size_t sz);

unsigned int joaat(char *buf, size_t length);

void clearText();

void delayedPrint(char *str);

void drawCat();

void drawHead();

const unsigned int CHAR_DELAY = 40000;

const size_t BUF_SIZE = 256;

int main() {
    setlocale(LC_ALL, "");
    initscr();

    char buffer[BUF_SIZE] = "";

    bool proceed = true;

    getlogin_r(buffer, BUF_SIZE);

    curs_set(0);
    drawHead();
    move(15, 0);
    drawCat();
    move(17, 18);
    delayedPrint("Hello, ");
    delayedPrint(buffer);
    move(18, 18);
    delayedPrint("You must be desperate to crack this program.");
    move(19, 18);
    delayedPrint("Let me help you!");

    while (proceed) {
        move(30, 0);
        printw("Enter file name: ");
        curs_set(1);
        scanw("%s", buffer);
        if(*buffer == 0) {
            clearText();
            move(17, 18);
            delayedPrint("Goodbye!");
            sleep(2);
            break;
        }
        curs_set(0);
        move(30, 0);
        clrtoeol();
        clearText();
        refresh();
        move(17, 18);
        delayedPrint("Let me see...");
        sleep(3);
        char *program = nullptr;
        size_t sz = loadFile(buffer, &program);
        PATCH_ERROR result = patchFile((unsigned char *) program, sz);
        move(17, 18);
        clrtoeol();
        switch (result) {
            case OK:
                saveFile(buffer, program, sz);
                move(17, 18);
                delayedPrint("Done! That was really easy!");
                move(18, 18);
                delayedPrint("Goodbye!");
                proceed = false;
                sleep(2);
                break;

            case SIZE_MISMATCH:
                move(17, 18);
                delayedPrint("Whooops! Looks like I can't help you with this one.");
                move(18, 18);
                delayedPrint("Let's try another one, shall we?");
                break;

            case HASH_MISMATCH:
                move(17, 18);
                delayedPrint("Whooops! Looks like this one is already patched, or I can't really help you.");
                move(18, 18);
                delayedPrint("Let's try another one, shall we?");
                break;
        }
        free(program);
        refresh();
    }
    endwin();
    return 0;
}

void clearText() {
    move(17, 18);
    clrtoeol();
    move(18, 18);
    clrtoeol();
    move(19, 18);
    clrtoeol();
}

void delayedPrint(char *str) {
    while (*str) {
        printw("%c", *str);
        str++;
        refresh();
        usleep(CHAR_DELAY);
    }
}

void drawHead() {
    printw("                                 __    __  ______   ______  __    __ ________ _______   ______   ______  ________ \n"
           "                                |  \\  |  \\/      \\ /      \\|  \\  /  \\        \\       \\ /      \\ /      \\|        \\\n"
           "                                | ▓▓  | ▓▓  ▓▓▓▓▓▓\\  ▓▓▓▓▓▓\\ ▓▓ /  ▓▓ ▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓\\  ▓▓▓▓▓▓\\  ▓▓▓▓▓▓\\\\▓▓▓▓▓▓▓▓\n"
           "                                | ▓▓__| ▓▓ ▓▓__| ▓▓ ▓▓   \\▓▓ ▓▓/  ▓▓| ▓▓__   | ▓▓__| ▓▓ ▓▓   \\▓▓ ▓▓__| ▓▓  | ▓▓   \n"
           "                                | ▓▓    ▓▓ ▓▓    ▓▓ ▓▓     | ▓▓  ▓▓ | ▓▓  \\  | ▓▓    ▓▓ ▓▓     | ▓▓    ▓▓  | ▓▓   \n"
           "                                | ▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓ ▓▓   __| ▓▓▓▓▓\\ | ▓▓▓▓▓  | ▓▓▓▓▓▓▓\\ ▓▓   __| ▓▓▓▓▓▓▓▓  | ▓▓   \n"
           "                                | ▓▓  | ▓▓ ▓▓  | ▓▓ ▓▓__/  \\ ▓▓ \\▓▓\\| ▓▓_____| ▓▓  | ▓▓ ▓▓__/  \\ ▓▓  | ▓▓  | ▓▓   \n"
           "                                | ▓▓  | ▓▓ ▓▓  | ▓▓\\▓▓    ▓▓ ▓▓  \\▓▓\\ ▓▓     \\ ▓▓  | ▓▓\\▓▓    ▓▓ ▓▓  | ▓▓  | ▓▓   \n"
           "                                 \\▓▓   \\▓▓\\▓▓   \\▓▓ \\▓▓▓▓▓▓ \\▓▓   \\▓▓\\▓▓▓▓▓▓▓▓\\▓▓   \\▓▓ \\▓▓▓▓▓▓ \\▓▓   \\▓▓   \\▓▓   \n"
           "                                                                                  \n"
           "                                                                                  \n"
           "                                                                                  ");
}

void drawCat() {
    printw("    /\\___/\\\n"
           "   /       \\\n"
           "  l  ^   ^  l\n"
           "--l----*----l--\n"
           "   \\   w   /\n"
           "     ======\n"
           "   /       \\ __\n"
           "   l        l\\ \\\n"
           "   l        l/ /\n"
           "   l  l l   l /\n"
           "   \\ ml lm /_/");

//    "    .    _  .     _____________\n"
//    "   |\\_|/__/|    /             \\\n"
//    "  / / \\/ \\  \\  / Your message  \\\n"
//    " /__|O||O|__ \\ \\     here      /\n"
//    "|/_ \\_/\\_/ _\\ | \\  ___________/\n"
//    "| | (____) | ||  |/"
    refresh();
}

size_t loadFile(const char *filename, char **buf) {
    FILE *prog_file = fopen(filename, "rb");

    fseek(prog_file, 0, SEEK_END);
    size_t sz = ftell(prog_file);
    fseek(prog_file, 0, SEEK_SET);

    *buf = (char *) calloc(sz + 1, sizeof(char));

    fread(*buf, sizeof(char), sz, prog_file);
    fclose(prog_file);

    return sz;
}

PATCH_ERROR patchFile(unsigned char *buf, size_t sz) {
    if (sz != 5960)
        return SIZE_MISMATCH;

    if (joaat((char *) buf, sz) != 333717748)
        return HASH_MISMATCH;

    for (int i = 0x14b7; i < 0x14b7 + 0xc; i++) {
        buf[i] = 0x90;
    }

    buf[0x1529] = 0xeb;
    buf[0x158a] = 0xeb;
    buf[0x15bf] = 0xeb;
    buf[0x15c0] = 0x0;
    return NO_ERROR;
}

bool saveFile(const char *filename, const char *buf, size_t sz) {
    FILE *prog_file = fopen(filename, "wb");
    if(!prog_file)
        return true;
    fwrite(buf, sizeof(char), sz, prog_file);
    fclose(prog_file);
}

unsigned int joaat(char *buf, size_t length) {
    unsigned int hash = 0;
    for (int i = 0; i < length; i++) {
        hash += buf[i];
        hash += hash << 10;
        hash ^= hash >> 6;
    }
    hash += hash << 3;
    hash ^= hash >> 11;
    hash += hash << 15;
    return hash;
}