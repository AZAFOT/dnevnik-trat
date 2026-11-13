# Дневник трат

Приложение для телефона: учёт расходов и доходов, календарь месяца, места трат (с GPS), сводка и коэффициенты.

## Два способа пользоваться

| | Страница в Claude | Установленная версия (PWA) |
|---|---|---|
| Где | https://claude.ai/artifact/HvtiXBwAUXAMdZYkcbB9rv | https://azafot.github.io/dnevnik-trat/ (GitHub Pages из папки `docs/`) |
| Данные | облако Claude, личный раздел, синхронизация между устройствами | память телефона (браузер) |
| GPS | нет: окно Claude не даёт страницам геолокацию | да |
| Без интернета | нет | да |

Перенос записей между версиями: «Ещё» → «Скачать копию (JSON)» → в другой версии «Загрузить копию».

## Файлы

- `app.html` — исходник (его же публикует Claude как страницу).
- `build.ps1` — собирает `docs/` (index.html, манифест, service worker, иконки):
  `powershell -ExecutionPolicy Bypass -File build.ps1`
- `docs/` — готовая установочная версия.

## Размещение

Репозиторий https://github.com/AZAFOT/dnevnik-trat, GitHub Pages: ветка `main`, папка `/docs`.
На телефоне: открыть https://azafot.github.io/dnevnik-trat/ в Chrome или Safari → «Добавить на главный экран» →
при первой записи с GPS разрешить геолокацию.

Обновить опубликованное приложение после правок `app.html`:

    powershell -ExecutionPolicy Bypass -File build.ps1
    git add -A
    git commit -m "Обновление"
    git push

Через минуту GitHub Pages пересоберёт сайт. Чтобы телефон точно взял новую версию, в `build.ps1` поднимите
номер кэша `dnevnik-trat-v1` → `v2`.

Геолокация в браузерах работает только по HTTPS, поэтому открыть `index.html` как файл или по `http://192.168…` с GPS не получится.
