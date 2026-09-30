# march

Инструмент для скачивания, проверки, кэширования и запуска программ (бинарников, AppImage, архивов) из одного URL.

## Возможности

- Скачивание и кэширование по URL
- Проверка целостности: `--size`, `--md5`, `--sha256`
- Автоматический выбор способа запуска: AppImage, exe-файл или архив
- Распаковка архивов (`.tar.gz`, `.tar.xz`, `.zip`) с поиском исполняемого файла
- Кэш в `$MARCH_CACHE` (по умолчанию `$XDG_CACHE_HOME/march`)

## Использование

```
march [--size=N] [--md5=HASH] [--sha256=HASH] [--appimage|--exe|--archive] URL [ARGS ...]
```

Пример:

```sh
march --sha256=8e26ee9ce094c24e9c79a6221388e190ebd5eb94831b98d575d45978f45ea87a \
	https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/3.16
```

## Установка

Требуется [shelduck](https://github.com/legeyda/shelduck).

```sh
./run install          # соберёт и установит в ~/.local/bin
MARCH_INSTALL_PREFIX=/usr ./run install   # установка в другой префикс
```

## Ограничения

- Утилита `install` пока не реализована (`./run install` использует сборку через `shelduck resolve`).